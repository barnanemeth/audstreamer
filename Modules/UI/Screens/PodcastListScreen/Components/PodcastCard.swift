//
//  PodcastCard.swift
//  UI
//
//  Created by Barna Nemeth on 2026. 01. 22..
//

import SwiftUI

import Domain
import UIComponentKit

internal import NukeUI

struct PodcastCard: View {

    // MARK: Properties

    let podcast: Podcast
    let transitionNamespace: Namespace.ID

    // MARK: - UI
    var body: some View {
        VStack(spacing: .zero) {
            image
            title
        }
        .matchedTransitionSource(id: podcast, in: transitionNamespace)
        .background(Asset.Colors.surfaceElevated.swiftUIColor)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Asset.Colors.surfaceMuted.swiftUIColor, radius: 8)
    }
}

// MARK: - Helpers

private extension PodcastCard {
    var image: some View {
        ZStack {
            Color.clear
        }
        .aspectRatio(1, contentMode: .fit)
        .background {
            LazyImage(url: podcast.imageURL) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipped()
                }
            }
        }
        .clipped()
    }

    var title: some View {
        VStack(alignment: .leading) {
            Text(podcast.title)
                .font(.bodySecondaryText)
                .fontWeight(.semibold)
                .foregroundStyle(Asset.Colors.labelPrimary.swiftUIColor)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(podcast.author ?? "")
                .font(.captionText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(Asset.Colors.labelSecondary.swiftUIColor)
        }
        .lineLimit(1)
        .padding(16)
    }
}
