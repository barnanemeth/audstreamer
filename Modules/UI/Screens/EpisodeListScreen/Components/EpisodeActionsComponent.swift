//
//  EpisodeActionsComponent.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2025. 12. 28..
//

import SwiftUI

import Common
import Domain
import UIComponentKit

internal import SFSafeSymbols

struct EpisodeActionsComponent: View {

    // MARK: Constants

    private enum Constant {
        static let thumbnailAspectRatio: CGFloat = 16 / 9
        static let thumbnailWidth: CGFloat = 106
        static let buttonsHeight: CGFloat = 40
    }

    // MARK: Properties

    let episode: Episode
    let isWatchAvailable: Bool
    let isPlaying: Bool
    let onPlayPauseTap: () async -> Void
    let onFavouriteTap: () async -> Void
    let onDownloadTap: () async -> Void
    let onWatchTap: () async -> Void

    // MARK: UI

    var body: some View {
        VStack(spacing: 12) {
            buttons
            details
        }
    }
}

// MARK: - Helpers

extension EpisodeActionsComponent {
    private var buttons: some View {
        HStack {
            button(symbol: isPlaying ? .pauseFill : .playFill, action: onPlayPauseTap)
            button(symbol: episode.isFavourite ? .bookmarkSlashFill : .bookmarkFill, action: onFavouriteTap)
            button(symbol: episode.isDownloaded ? .arrowDownCircleBadgeXmarkFill : .arrowDownCircleFill, action: onDownloadTap)
            if isWatchAvailable {
                button(symbol: episode.isOnWatch ? .applewatchSlash : .applewatch, action: onWatchTap)
            }
        }
        .frame(height: Constant.buttonsHeight)
    }

    private func button(symbol: SFSymbol, action: @escaping () async -> Void) -> some View {
        AsyncButton {
            await action()
        } label: {
            Image(systemSymbol: symbol)
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(ActionButtonStyle())
    }

    private var details: some View {
        HStack {
            Text(L10n.publishDate(episode.publishDate.formatted(date: .abbreviated, time: .omitted)))
                .multilineTextAlignment(.leading)

            Spacer()

            let durationString = if episode.duration > .zero {
                Double(episode.duration).secondsToHoursMinutesSecondsString
            } else {
                "--:--:--"
            }
            Text(L10n.duration(durationString))
                .multilineTextAlignment(.trailing)
        }
        .font(.captionText)
        .lineLimit(2)
        .foregroundStyle(Asset.Colors.labelPrimary.swiftUIColor)
    }
}
