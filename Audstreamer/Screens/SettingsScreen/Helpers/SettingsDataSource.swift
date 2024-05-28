//
//  SettingsDataSource.swift
//  Audstreamer-ios
//
//  Created by Barna Nemeth on 2022. 11. 16..
//

import UIKit

final class SettingsDataSource: UITableViewDiffableDataSource<SettingsSection, SettingsItem> {
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sectionIdentifier(for: section)?.title
    }
}
