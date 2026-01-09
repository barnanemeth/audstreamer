//
//  EpisodeRow.swift
//  AudstreamerWatch
//
//  Created by Barna Nemeth on 2025. 12. 21..
//

import SwiftUI

import Common
import Domain

import SFSafeSymbols

struct EpisodeRow: View {

    // MARK: Properties

    let data: Data

    // MARK: UI

    var body: some View {
        VStack(alignment: .leading) {
            title
            Divider()
            transeffering
        }
    }
}

// MARK: - Helpers

extension EpisodeRow {
    private var title: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(data.episode.title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)

            if data.isPlaying {
                Image(systemSymbol: .playCircleFill)
            }
        }
    }

    @ViewBuilder
    private var transeffering: some View {
        let (symbol, text, color): (SFSymbol, String, Color) = switch data.transferringState {
        case .inProgress: (.arrowTrianglehead2ClockwiseRotate90CircleFill, L10n.transferring, Asset.Colors.warning.swiftUIColor)
        case .finished: (.checkmarkCircleFill, L10n.transferred, Asset.Colors.success.swiftUIColor)
        }

        HStack {
            Image(systemSymbol: symbol)
            Text(verbatim: text)
        }
        .font(.footnote)
        .foregroundColor(color)
    }
}

// MARK: - Data

extension EpisodeRow {
    struct Data: Hashable, Equatable {
        let episode: Episode
        let isPlaying: Bool
        let transferringState: TransferringState
    }

    enum TransferringState: Hashable, Equatable {
        case inProgress
        case finished
    }
}
