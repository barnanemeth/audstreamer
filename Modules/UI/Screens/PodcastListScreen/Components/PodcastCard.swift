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

    // MARK: Private properties

    @Environment(\.colorScheme) private var colorScheme: ColorScheme
    private var backgroundColor: Color {
        switch colorScheme {
        case .light: .white
        case .dark: .gray.opacity(0.1)
        @unknown default: .white
        }
    }

    // MARK: - UI
    var body: some View {
        VStack(spacing: .zero) {
            image
            title
        }
        .matchedTransitionSource(id: podcast, in: transitionNamespace)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 8)
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
