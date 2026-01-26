//
//  EpisodeHeaderComponent.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2025. 12. 28..
//

import SwiftUI

import Domain
import UIComponentKit

internal import NukeUI
internal import SFSafeSymbols

struct EpisodeHeaderComponent: View {

    // MARK: Constants

    private enum Constant {
        static let thumbnailSize = CGSize(width: 62, height: 62)
        static let playedThresholdSeconds = 10
    }

    // MARK: Properties

    let episode: Episode
    var shouldShowIndicators = false

    // MARK: Private properties

    @Namespace private var namespace
    private var isIndicatorsVisible: Bool {
        shouldShowIndicators && (episode.isFavourite || episode.isDownloaded || episode.isOnWatch)
    }
    private var playingProgress: Float? {
        guard let lastPosition = episode.lastPosition, episode.duration > .zero, lastPosition >= Constant.playedThresholdSeconds else { return nil }
        return Float(lastPosition) / Float(episode.duration)
    }

    // MARK: UI

    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                thumbnail
                titleSection
                indicators
            }

            playingProgressIndicator
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Helpers

extension EpisodeHeaderComponent {
    private var thumbnail: some View {
        ZStack {
            Color.clear
            LazyImage(url: episode.thumbnail) { state in
                if state.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                } else if let image = state.image {
                    image
                        .resizable()
                        .scaledToFill()
                }
            }
        }
        .frame(width: Constant.thumbnailSize.width, height: Constant.thumbnailSize.height)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var titleSection: some View {
        VStack(spacing: 8) {
            Text(episode.podcastTitle.uppercased())
                .fontWeight(.semibold)
                .foregroundStyle(Asset.Colors.labelSecondary.swiftUIColor)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(episode.title)
                .multilineTextAlignment(.leading)
                .foregroundStyle(Asset.Colors.labelPrimary.swiftUIColor)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(bottomInfoText)
                .foregroundStyle(Asset.Colors.labelSecondary.swiftUIColor)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.captionText)
    }

    @ViewBuilder
    private var indicators: some View {
        if isIndicatorsVisible {
            VStack {
                HStack(spacing: 8) {
                    if episode.isFavourite {
                        Image(systemSymbol: .bookmarkFill)
                    }
                    if episode.isDownloaded {
                        Image(systemSymbol: .arrowDownCircleFill)
                    }
                    if episode.isOnWatch {
                        Image(systemSymbol: .applewatch)
                    }
                }
                .foregroundStyle(Asset.Colors.accentPrimary.swiftUIColor)

                Spacer()
            }
        }
    }

    @ViewBuilder
    private var playingProgressIndicator: some View {
        if let playingProgress {
            ProgressView(value: playingProgress)
                .progressViewStyle(.linear)
                .tint(Asset.Colors.accentPrimary.swiftUIColor)
        }
    }

    private var bottomInfoText: String {
        var text = "\(episode.publishDate.formatted(date: .abbreviated, time: .omitted))"
        if episode.duration > .zero {
            let duration = Duration(secondsComponent: Int64(episode.duration), attosecondsComponent: .zero)
            let durationText = duration.formatted(.units(allowed: [.minutes]))
            text.append(" · \(durationText)")
        }
        return text
    }
}
