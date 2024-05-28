//
//  DefaultFilterService.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2022. 11. 13..
//

import Foundation
import Combine

final class DefaultFilterService {

    // MARK: Dependencies

    @Injected private var watchConnectivityService: WatchConnectivityService

    // MARK: Private properties

    private var cancellables = Set<AnyCancellable>()
    private let currentAttributesSubject = CurrentValueSubject<[FilterAttribute], Error>([])

    // MARK: Init

    init() {
        initCurrentAttributes()
        subscribeToWatchAvailability()
    }
}

// MARK: - FilterService

extension DefaultFilterService: FilterService {
    func getAttributes() -> AnyPublisher<[FilterAttribute], Error> {
        currentAttributesSubject.eraseToAnyPublisher()
    }

    func setAttribute(_ attribute: FilterAttribute) -> AnyPublisher<Void, Error> {
        currentAttributesSubject
            .first()
            .map { attributes -> [FilterAttribute] in
                var attributes = attributes
                guard let index = attributes.firstIndex(where: { $0.type == attribute.type }) else { return attributes }
                attributes[index].isActive = attribute.isActive
                return attributes
            }
            .map { [unowned self] in self.currentAttributesSubject.send($0) }
            .eraseToAnyPublisher()
    }
}

// MARK: - Helpers

extension DefaultFilterService {
    private func initCurrentAttributes() {
        let defaultAttributeTypes: [FilterAttributeType] = [.favorites, .downloads]
        let attributes = defaultAttributeTypes.map { FilterAttribute(type: $0) }
        currentAttributesSubject.send(attributes)
    }

    private func subscribeToWatchAvailability() {
        watchConnectivityService.isAvailable()
            .flatMap { [unowned self] isWatchAvailable in
                let currentAttributes = self.currentAttributesSubject.first()
                let isWatchAvailablePublisher = Just(isWatchAvailable).setFailureType(to: Error.self)

                return Publishers.Zip(currentAttributes, isWatchAvailablePublisher)
            }
            .map { [unowned self] in self.makeAttributes(attributes: $0, isWatchAvailable: $1) }
            .sink { [unowned self] in self.currentAttributesSubject.send($0) }
            .store(in: &cancellables)
    }

    private func makeAttributes(attributes: [FilterAttribute], isWatchAvailable: Bool) -> [FilterAttribute] {
        var attributes = attributes
        if isWatchAvailable && attributes.last?.type != .watch {
            attributes.append(FilterAttribute(type: .watch))
        } else if attributes.last?.type == .watch {
            attributes.removeLast()
        }
        return attributes
    }
}
