//
//  LoginScreen.swift
//  Audstreamer
//
//  Created by Németh Barna on 2021. 02. 16..
//

import UIKit
import Combine
import AuthenticationServices
import UserNotifications

final class LoginScreen: UIViewController, Screen {

    // MARK: Constants

    private enum Constant {
        static let infoImageSize: CGFloat = 240
    }

    // MARK: Screen

    @Injected var viewModel: LoginScreenViewModel

    // MARK: UI

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let infoImageView = UIImageView(image: Asset.Images.femaleMaleCircle.image)
    private let cancelButton = BaseButton()
    private let activityIndicatorView = UIActivityIndicatorView(style: .large)
    private lazy var authorizationAppleIDButton: AppleAuthorizationButton = {
        let authorizationButton: AppleAuthorizationButton
        if #available(iOS 13.2, *) {
            let buttonStyle: ASAuthorizationAppleIDButton.Style = traitCollection.userInterfaceStyle == .dark ?
                .white :
                .black
            authorizationButton = AppleAuthorizationButton(
                authorizationButtonType: .signIn,
                authorizationButtonStyle: buttonStyle
            )
        } else {
            authorizationButton = AppleAuthorizationButton()
        }
        return authorizationButton
    }()

    // MARK: Private properties

    private var cancellables = Set<AnyCancellable>()
    private var isLoading = false {
        didSet {
            if isLoading {
                activityIndicatorView.startAnimating()
                authorizationAppleIDButton.isHidden = true
                cancelButton.isEnabled = false
            } else {
                activityIndicatorView.stopAnimating()
                authorizationAppleIDButton.isHidden = false
                cancelButton.isEnabled = true
            }
        }
    }
}

// MARK: - Lifecycle

extension LoginScreen {
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupBindings()
    }
}

// MARK: - Setups

extension LoginScreen {
    private func setupUI() {
        view.backgroundColor = Asset.Colors.background.color

        setupTitleLabel()
        setupSubtitleLabel()
        setupInfoImageView()
        setupCancelButton()
        setupAuthorizationAppleIDButton()
        setupIndicatorView()
    }

    private func setupTitleLabel() {
        titleLabel.text = L10n.logIn
        titleLabel.textAlignment = .center
        titleLabel.textColor = Asset.Colors.primary.color
        titleLabel.font = UIFont.preferredFont(forTextStyle: .title1)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 56),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }

    private func setupSubtitleLabel() {
        subtitleLabel.text = L10n.logInInfo
        subtitleLabel.textAlignment = .center
        subtitleLabel.textColor = Asset.Colors.label.color
        subtitleLabel.font = UIFont.systemFont(ofSize: 17)
        subtitleLabel.numberOfLines = .zero
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 32),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }

    private func setupInfoImageView() {
        infoImageView.tintColor = Asset.Colors.primary.color
        infoImageView.contentMode = .scaleAspectFit
        infoImageView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(infoImageView)

        NSLayoutConstraint.activate([
            infoImageView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 64),
            infoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            infoImageView.widthAnchor.constraint(equalToConstant: Constant.infoImageSize),
            infoImageView.heightAnchor.constraint(equalToConstant: Constant.infoImageSize)
        ])
    }

    private func setupCancelButton() {
        cancelButton.setTitle(L10n.cancel, for: .normal)
        cancelButton.setTitleColor(Asset.Colors.primary.color, for: .normal)
        cancelButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(cancelButton)

        NSLayoutConstraint.activate([
            cancelButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cancelButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }

    private func setupAuthorizationAppleIDButton() {
        authorizationAppleIDButton.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(authorizationAppleIDButton)

        NSLayoutConstraint.activate([
            authorizationAppleIDButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            authorizationAppleIDButton.bottomAnchor.constraint(equalTo: cancelButton.topAnchor, constant: -32.0),
            authorizationAppleIDButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32.0),
            authorizationAppleIDButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32.0),
            authorizationAppleIDButton.heightAnchor.constraint(equalToConstant: 56.0)
        ])
    }

    private func setupIndicatorView() {
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(activityIndicatorView)

        NSLayoutConstraint.activate([
            activityIndicatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicatorView.bottomAnchor.constraint(equalTo: cancelButton.topAnchor, constant: -32.0),
            activityIndicatorView.heightAnchor.constraint(equalToConstant: 56.0)
        ])
    }

    private func setupBindings() {
        viewModel.$isLoading
            .assign(to: \.isLoading, on: self, ownership: .unowned)
            .store(in: &cancellables)

        authorizationAppleIDButton.action = viewModel.authorizeAction
        cancelButton.action = CocoaAction { [unowned self] in self.dismiss() }
        viewModel.dismissAction = CocoaAction { [unowned self] in self.dismiss() }
        viewModel.showErrorlAlertAction = Action<Error, Never> { [unowned self] error in
            guard let error = try? error.get() else { return }
            self.showAlert(for: error)
        }
    }
}

// MARK: - Helpers

extension LoginScreen {
    private func dismiss() {
        guard let presentationController = presentationController else { return }
        presentationController.delegate?.presentationControllerWillDismiss?(presentationController)
        dismiss(animated: true, completion: nil)
    }
}
