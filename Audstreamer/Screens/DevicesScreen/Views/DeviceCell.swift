//
//  DeviceCell.swift
//  Audstreamer
//
//  Created by Németh Barna on 2021. 03. 09..
//

import UIKit

final class DeviceCell: UITableViewCell {

    // MARK: Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)

        tintColor = Asset.Colors.primary.color
        selectionStyle = .default
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// MARK: - Lifecycle

extension DeviceCell {
    override func prepareForReuse() {
        super.prepareForReuse()

        imageView?.image = nil
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        accessoryType = selected ? .checkmark : .none
    }
}

// MARK: - Public methods

extension DeviceCell {
    func setup(with device: Device) {
        textLabel?.text = device.name
        imageView?.image = getImageForDevice(device)
    }
}

// MARK: - Helpers

extension DeviceCell {
    private func getImageForDevice(_ device: Device) -> UIImage? {
        switch device.type {
        case .iPhone: return Asset.symbol(.iphone)
        case .iPad: return Asset.symbol(.ipad)
        default: return nil
        }
    }
}
