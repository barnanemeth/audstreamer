//
//  CustomButtonStyle+PrimaryPreview.swift
//  UIComponentKit
//
//  Created by Barna Nemeth on 2024. 12. 12..
//

import SwiftUI

#Preview("Primary") {
    ScrollView {
        Button("Normal") { }
            .buttonStyle(.primary())

        Button("Disabled") { }
            .buttonStyle(.primary())
            .disabled(true)

        Button("Normal") { }
            .buttonStyle(.primary(fill: true))

        Button("Disabled") { }
            .buttonStyle(.primary(fill: true))
            .disabled(true)

        Button("Normal") { }
            .buttonStyle(.primary(icon: Asset.Images.play.swiftUIImage))

        Button("Disabled") { }
            .buttonStyle(.primary(icon: Asset.Images.play.swiftUIImage))
            .disabled(true)

        Button("Normal") { }
            .buttonStyle(.primary(fill: true, icon: Asset.Images.play.swiftUIImage))

        Button("Disabled") { }
            .buttonStyle(.primary(fill: true, icon: Asset.Images.play.swiftUIImage))
            .disabled(true)

        Button("Normal") { }
            .buttonStyle(.primary(size: .small))

        Button("Disabled") { }
            .buttonStyle(.primary(size: .small))
            .disabled(true)

        Button("Normal") { }
            .buttonStyle(.primary(size: .small, fill: true))

        Button("Disabled") { }
            .buttonStyle(.primary(size: .small, fill: true))
            .disabled(true)

        Button("Normal") { }
            .buttonStyle(.primary(size: .small, icon: Asset.Images.play.swiftUIImage))

        Button("Disabled") { }
            .buttonStyle(.primary(size: .small, icon: Asset.Images.play.swiftUIImage))
            .disabled(true)

        Button("Normal") { }
            .buttonStyle(.primary(size: .small, fill: true, icon: Asset.Images.play.swiftUIImage))

        Button("Disabled") { }
            .buttonStyle(.primary(size: .small, fill: true, icon: Asset.Images.play.swiftUIImage))
            .disabled(true)
    }
    .padding()
}

#Preview("Secondary") {
    ScrollView {
        Button("Normal") { }
            .buttonStyle(.secondary())

        Button("Disabled") { }
            .buttonStyle(.secondary())
            .disabled(true)

        Button("Normal") { }
            .buttonStyle(.secondary(fill: true))

        Button("Disabled") { }
            .buttonStyle(.secondary(fill: true))
            .disabled(true)

        Button("Normal") { }
            .buttonStyle(.secondary(icon: Asset.Images.play.swiftUIImage))

        Button("Disabled") { }
            .buttonStyle(.secondary(icon: Asset.Images.play.swiftUIImage))
            .disabled(true)

        Button("Normal") { }
            .buttonStyle(.secondary(fill: true, icon: Asset.Images.play.swiftUIImage))

        Button("Disabled") { }
            .buttonStyle(.secondary(fill: true, icon: Asset.Images.play.swiftUIImage))
            .disabled(true)

        Button("Normal") { }
            .buttonStyle(.secondary(size: .small))

        Button("Disabled") { }
            .buttonStyle(.secondary(size: .small))
            .disabled(true)

        Button("Normal") { }
            .buttonStyle(.secondary(size: .small, fill: true))

        Button("Disabled") { }
            .buttonStyle(.secondary(size: .small, fill: true))
            .disabled(true)

        Button("Normal") { }
            .buttonStyle(.secondary(size: .small, icon: Asset.Images.play.swiftUIImage))

        Button("Disabled") { }
            .buttonStyle(.secondary(size: .small, icon: Asset.Images.play.swiftUIImage))
            .disabled(true)

        Button("Normal") { }
            .buttonStyle(.secondary(size: .small, fill: true, icon: Asset.Images.play.swiftUIImage))

        Button("Disabled") { }
            .buttonStyle(.secondary(size: .small, fill: true, icon: Asset.Images.play.swiftUIImage))
            .disabled(true)
    }
    .padding()
}

#Preview("Text") {
    ScrollView {
        Button("Normal") { }
            .buttonStyle(.text())

        Button("Disabled") { }
            .buttonStyle(.text())
            .disabled(true)

        Button("Normal") { }
            .buttonStyle(.text(fill: true))

        Button("Disabled") { }
            .buttonStyle(.text(fill: true))
            .disabled(true)

        Button("Normal") { }
            .buttonStyle(.text(icon: Asset.Images.play.swiftUIImage))

        Button("Disabled") { }
            .buttonStyle(.text(icon: Asset.Images.play.swiftUIImage))
            .disabled(true)

        Button("Normal") { }
            .buttonStyle(.text(fill: true, icon: Asset.Images.play.swiftUIImage))

        Button("Disabled") { }
            .buttonStyle(.text(fill: true, icon: Asset.Images.play.swiftUIImage))
            .disabled(true)

        Button("Normal") { }
            .buttonStyle(.text(size: .small))

        Button("Disabled") { }
            .buttonStyle(.text(size: .small))
            .disabled(true)

        Button("Normal") { }
            .buttonStyle(.text(size: .small, fill: true))

        Button("Disabled") { }
            .buttonStyle(.text(size: .small, fill: true))
            .disabled(true)

        Button("Normal") { }
            .buttonStyle(.text(size: .small, icon: Asset.Images.play.swiftUIImage))

        Button("Disabled") { }
            .buttonStyle(.text(size: .small, icon: Asset.Images.play.swiftUIImage))
            .disabled(true)

        Button("Normal") { }
            .buttonStyle(.text(size: .small, fill: true, icon: Asset.Images.play.swiftUIImage))

        Button("Disabled") { }
            .buttonStyle(.text(size: .small, fill: true, icon: Asset.Images.play.swiftUIImage))
            .disabled(true)
    }
    .padding()
}
