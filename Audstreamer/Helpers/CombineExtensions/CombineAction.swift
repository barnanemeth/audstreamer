//
//  CombineAction.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 10. 16..
//

import Foundation
import Combine

/// Typealias for compatibility with UIButton's action property.
public typealias CocoaAction = Action<Void, Never>

extension CocoaAction {
    public convenience init(_ defaultAction: (() -> Void)? = nil) {
        self.init { _ in
            defaultAction?()
        }
    }

    public convenience init<Object: AnyObject>(_ defaultAction: @escaping ((Object) -> () -> Void), in object: Object) {
        self.init { [weak object] _ in
            guard let object = object else { return }
            defaultAction(object)()
        }
    }

    @discardableResult public func execute() -> AnyPublisher<InputType, ErrorType> {
        execute(())
    }
}

extension Action where ErrorType == Never {
    public convenience init<Object: AnyObject>(_ defaultAction: @escaping ((Object) -> (InputType) -> Void),
                                               in object: Object) {
        self.init { [weak object] result in
            guard let object = object else { return }
            guard case .success(let value) = result else { return }
            defaultAction(object)(value)
        }
    }
}

public final class Action<InputType, ErrorType: Error> {
    private let subject = PassthroughSubject<InputType, ErrorType>()
    private var cancellables = Set<AnyCancellable>()
    private var defaultActionFactory: ((Result<InputType, ErrorType>) -> AnyPublisher<Void, Never>)?

    public var publisher: AnyPublisher<InputType, ErrorType> {
        subject
            .receive(on: DispatchQueue.main)
            .share()
            .eraseToAnyPublisher()
    }

    public init(_ defaultAction: ((Result<InputType, ErrorType>) -> Void)?) {
        guard let defaultAction = defaultAction else { return }
        defaultActionFactory = { result in
            Just({ defaultAction(result) }() ).eraseToAnyPublisher()
        }
    }

    public init(_ actionPublisher: AnyPublisher<Void, Never>) {
        defaultActionFactory = { result in
            if case .success = result {
                return actionPublisher
            } else {
                return Just(()).eraseToAnyPublisher()
            }
        }
    }

    public convenience init<Object: AnyObject>(
        _ defaultAction: @escaping ((Object) -> (Result<InputType, ErrorType>) -> Void),
        in object: Object) {
        self.init { [weak object] result in
            guard let object = object else { return }
            defaultAction(object)(result)
        }
    }

    public init(firstAction: Action<InputType, ErrorType>, secondAction: Action<InputType, ErrorType>) {
        defaultActionFactory = { result in
            firstAction.execute(result)
                .flatMap { _ in
                    secondAction
                        .execute(result)
                        .toVoid()
                        .eraseToAnyPublisher()
                }
                .toVoid()
                .replaceError(with: ())
                .eraseToAnyPublisher()
        }
    }

    @discardableResult
    public func execute(_ closure: @autoclosure () -> Result<InputType, ErrorType>)
    -> AnyPublisher<InputType, ErrorType> {
        let result = closure()
        let defaultActionPublisher = defaultActionFactory?(result) ?? Just(()).eraseToAnyPublisher()
        let bufferSubject = ReplaySubject<InputType, ErrorType>(bufferSize: 1)

        bufferSubject.sink(
            receiveCompletion: { [weak self] completion in
                self?.subject.send(completion: completion)
            }, receiveValue: { [weak self] value in
                self?.subject.send(value)
            })
            .store(in: &cancellables)

        defaultActionPublisher
            .first()
            .flatMap { _ -> AnyPublisher<Void, Never> in
                switch result {
                case .success(let value):
                    return Just({ bufferSubject.send(value) }() )
                        .eraseToAnyPublisher()
                case .failure(let error):
                    return Just({ bufferSubject.send(completion: .failure(error)) }() )
                        .eraseToAnyPublisher()
                }
            }
            .sink()
            .store(in: &cancellables)

        return bufferSubject
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    @discardableResult
    public func execute(_ closure: @autoclosure () -> InputType) -> AnyPublisher<InputType, ErrorType> {
        execute(.success(closure()))
    }

    @discardableResult
    public func execute(_ closure: @autoclosure () -> ErrorType) -> AnyPublisher<InputType, ErrorType> {
        execute(.failure(closure()))
    }
}

// Publisher extension to create Action easier

extension Publisher where Output == Void, Failure == Never {
    public var asCocoaAction: CocoaAction {
        CocoaAction(self.receive(on: DispatchQueue.main).eraseToAnyPublisher())
    }
}
