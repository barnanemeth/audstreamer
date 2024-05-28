//
//  ImagePreviewScreen.swift
//  Audstreamer-ios
//
//  Created by Barna Nemeth on 2022. 12. 24..
//

import UIKit
import Combine

import Nuke

final class ImagePreviewScreen: UIViewController {

    // MARK: Constants

    private enum Constant {
        static let defaultSize = CGSize(width: 200, height: 200)
    }

    // MARK: UI

    private let imageView = UIImageView()
    private let activityIndicator = UIActivityIndicatorView(style: .large)

    // MARK: Private properties

    private var cancellables = Set<AnyCancellable>()

    private let imageURL: URL

    // MARK: Init

    init(imageURL: URL) {
        self.imageURL = imageURL

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// MARK: - Lifecycle

extension ImagePreviewScreen {
    override func viewDidLoad() {
        super.viewDidLoad()

        preferredContentSize = Constant.defaultSize

        setupUI()
        fetchImage()
    }
}

// MARK: - Setups

extension ImagePreviewScreen {
    private func setupUI() {
        setupImageView()
        setupActivityIndicator()
    }

    private func setupImageView() {
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(imageView)

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupActivityIndicator() {
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func fetchImage() {
        ImagePipeline.shared.imagePublisher(with: imageURL)
            .sink { [unowned self] result in
                self.preferredContentSize = result.image.size * result.image.scale
                self.imageView.image = result.image
            }
            .store(in: &cancellables)
    }
}
