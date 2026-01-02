//
//  ProgressBar.swift
//  AudstreamerWatch
//
//  Created by Barna Nemeth on 2025. 12. 20..
//

import SwiftUI

struct ProgressBar: View {

    // MARK: Properties

    let progress: Float

    // MARK: Private properties

    private var normalizedProgress: CGFloat {
        min(1, max(0, CGFloat(progress)))
    }

    // MARK: UI

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.primary.opacity(0.25))
                    .frame(maxWidth: .infinity)

                if progress > .zero {
                    Capsule()
                        .fill(Color.primary)
                        .frame(width: proxy.size.width * normalizedProgress, alignment: .leading)
                }
            }
            .frame(height: 4)
        }
    }
}
