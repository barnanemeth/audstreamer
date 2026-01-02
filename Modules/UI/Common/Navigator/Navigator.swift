//
//  Navigator.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2025. 12. 21..
//

import UIKit

import Common
import UIComponentKit

public protocol NavigatorPublic {
    func setup(with window: UIWindow?)
}

final class Navigator: NSObject {

    // MARK: Private properties

    private var window: UIWindow?
    private var interactiveSheetDismissHandler: (() -> Void)?
    private var topViewController: UIViewController? {
        guard let rootViewController = topViewController(with: window?.rootViewController) else { return nil }
        let currentViewController = rootViewController.presentedViewController ?? rootViewController
        return topViewController(with: currentViewController)
    }
}

// MARK: - Navigator

extension Navigator: NavigatorPublic {
    func setup(with window: UIWindow?) {
        self.window = window

        self.window?.tintColor = Asset.Colors.primary.color
        self.window?.makeKeyAndVisible()

        let loadingScreen: LoadingScreen = Resolver.resolve()
        window?.rootViewController = loadingScreen
    }
}

// MARK: - Internal methods

extension Navigator {
    func present(_ screen: UIViewController,
                 aninamted: Bool = true,
                 completion: (() -> Void)? = nil,
                 interactiveSheetDismissHandler: (() -> Void)? = nil) {
        if let interactiveSheetDismissHandler {
            self.interactiveSheetDismissHandler = interactiveSheetDismissHandler
            screen.presentationController?.delegate = self
        }
        topViewController?.present(screen, animated: true)
    }

    func presentPopover(_ screen: UIViewController,
                        sourceView: UIView,
                        animated: Bool = true,
                        completion: (() -> Void)? = nil) {
        screen.modalPresentationStyle = .popover
        screen.modalTransitionStyle = .crossDissolve
        screen.popoverPresentationController?.sourceView = sourceView
        if let presentationControllerDelegate = topViewController as? UIAdaptivePresentationControllerDelegate {
            screen.presentationController?.delegate = presentationControllerDelegate
        }

        present(screen, aninamted: animated, completion: completion)
    }

    func presentAlertController(_ alertController: UIAlertController) {
        window?.rootViewController?.present(alertController, animated: true)
        topViewController?.present(alertController, animated: true)
    }

    func dismiss(animated: Bool = true, completion: (() -> Void)? = nil) {
        topViewController?.dismiss(animated: animated, completion: completion)
    }

    func dismissAndPresent(_ screen: UIViewController, animated: Bool = true, completion: (() -> Void)? = nil) {
        dismiss(animated: animated) { [weak self] in
            self?.present(screen, aninamted: animated, completion: completion)
        }
    }
}

// MARK: - Helpers

extension Navigator {
    private func topViewController(with viewController: UIViewController?) -> UIViewController? {
        if let navigationController = viewController as? UINavigationController {
            navigationController.visibleViewController
        } else {
            viewController
        }
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension Navigator: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        defer { interactiveSheetDismissHandler = nil }
        interactiveSheetDismissHandler?()
    }
}
