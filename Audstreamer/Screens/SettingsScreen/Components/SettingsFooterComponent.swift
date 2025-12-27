//
//  SettingsFooterComponent.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2025. 12. 22..
//

import SwiftUI

struct SettingsFooterComponent: View {

    // MARK: UI

    var body: some View {
        VStack(spacing: 12) {
            Asset.Images.logoLarge.swiftUIImage
                .resizable()
                .frame(width: 32, height: 32)

            Text(About.versionString)
                .fontWeight(.semibold)

            Text(About.copyrightString)
                .fontWeight(.regular)
        }
        .font(.system(size: 13))
        .foregroundStyle(Asset.Colors.label.swiftUIColor)
    }
}
