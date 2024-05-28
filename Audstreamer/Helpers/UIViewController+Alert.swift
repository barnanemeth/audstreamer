//
//  UIViewController+Alert.swift
//  Audstreamer
//
//  Created by Németh Barna on 2020. 12. 08..
//

import UIKit

extension UIViewController {
    func showAlert(title: String?, message: String?, completion: (() -> Void)? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: L10n.ok, style: .default, handler: { _ in
            completion?()
        })
        alertController.addAction(action)
        present(alertController, animated: true, completion: nil)
    }

    func showAlert(for error: Error, completion: (() -> Void)? = nil) {
        showAlert(title: L10n.error, message: error.localizedDescription, completion: completion)
    }
}
