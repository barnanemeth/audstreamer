//
//  LoadingScreen.swift
//  Audstreamer
//
//  Created by Németh Barna on 2020. 12. 08..
//

import Foundation
import UIKit
import Combine

import Lottie

final class LoadingScreen: UIViewController, Screen {

    // MARK: Cosntants

    private enum Constant {
        static let logoVerticalOffset: CGFloat = -20
        static let logoMaximumWidth: CGFloat = 294
        static let horizontalPadding: CGFloat = 36
        static let bottomPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 8
    }

    // MARK: Screen

    @Injected var viewModel: LoadingScreenViewModel

    // MARK: UI

    private lazy var loadingAnimationView: LottieAnimationView = {
        let path = Bundle.main.url(forResource: "LoadingAnimation", withExtension: "json")?.path
        guard let path = path else { preconditionFailure("Cannot load resource") }
        let engine = RenderingEngine.coreAnimation
        let option = RenderingEngineOption.specific(engine)
        let config = LottieConfiguration(renderingEngine: option)
        return LottieAnimationView(filePath: path, configuration: config)
    }()
    private let loadingLabel = UILabel()

    // MARK: Private properties

    private var cancellables = Set<AnyCancellable>()
}

// MARK: - Lifecycle

extension LoadingScreen {
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupBindings()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        viewModel.fetchData()
    }
}

// MARK: - Setups

extension LoadingScreen {
    private func setupUI() {
        view.backgroundColor = Asset.Colors.background.color

        setupLoadingAnimationView()
        setupLoadingLabel()
    }

    private func setupLoadingAnimationView() {
        loadingAnimationView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(loadingAnimationView)

        let leading = loadingAnimationView.leadingAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.leadingAnchor,
            constant: Constant.horizontalPadding
        )
        leading.priority = .defaultHigh
        let trailing = loadingAnimationView.trailingAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.trailingAnchor,
            constant: -Constant.horizontalPadding
        )
        trailing.priority = .defaultHigh
        NSLayoutConstraint.activate([
            loadingAnimationView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingAnimationView.centerYAnchor.constraint(
                equalTo: view.centerYAnchor,
                constant: Constant.logoVerticalOffset
            ),
            loadingAnimationView.widthAnchor.constraint(equalTo: loadingAnimationView.heightAnchor),
            loadingAnimationView.widthAnchor.constraint(lessThanOrEqualToConstant: Constant.logoMaximumWidth),
            leading,
            trailing
        ])
    }

    private func setupLoadingLabel() {
        loadingLabel.text = L10n.loading
        loadingLabel.translatesAutoresizingMaskIntoConstraints = false
        loadingLabel.textAlignment = .center
        loadingLabel.textColor = Asset.Colors.label.color
        loadingLabel.font = UIFont.preferredFont(forTextStyle: .callout)

        view.addSubview(loadingLabel)

        NSLayoutConstraint.activate([
            loadingLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingLabel.bottomAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                constant: -Constant.bottomPadding
            )
        ])
    }

    private func setupBindings() {
        viewModel.$isLoading
            .dropFirst()
            .sink { [unowned self] isLoading in
                if isLoading {
                    self.startLoadingAnimation()
                } else {
                    self.stopLoadingAnimation()
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Helpers

extension LoadingScreen {
    private func startLoadingAnimation() {
        loadingAnimationView.play(fromProgress: loadingAnimationView.currentProgress, toProgress: 1, loopMode: .loop)
    }

    private func stopLoadingAnimation() {
        loadingAnimationView.pause()
    }
}
