//
//  Badge.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2025. 12. 31..
//

import SwiftUI

struct Badge: View {

    // MARK: Constants

    private enum Constant {
        static let size: CGFloat = 12
    }

    // MARK: Properties

    let text: String

    // MARK: UI

    var body: some View {
        ZStack {
            GeometryReader { geo in
                let width = max(geo.size.width, Constant.size)
                let height: CGFloat = Constant.size

                Group {
                    if abs(width - height) < 0.5 {
                        Circle().fill(Asset.Colors.primary.swiftUIColor)
                    } else {
                        Capsule().fill(Asset.Colors.primary.swiftUIColor)
                    }
                }
                .frame(width: width, height: height)
            }

            Text(text)
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(Asset.Colors.white.swiftUIColor)
                .padding(.horizontal, 4)
                .frame(height: Constant.size)
        }
        .frame(height: Constant.size)
        .fixedSize()
    }
}
