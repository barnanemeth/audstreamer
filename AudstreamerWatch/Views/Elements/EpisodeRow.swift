//
//  EpisodeRow.swift
//  AudstreamerWatch
//
//  Created by Barna Nemeth on 2025. 12. 21..
//

//import SwiftUI
//
//struct EpisodeRow: View {
//
//    // MARK: Properties
//
//    let data: Data
//
//    // MARK: UI
//
//    var body: some View {
//        VStack(alignment: .leading) {
//            title
//            Divider()
//            transeffering
//        }
//    }
//}
//
//// MARK: - Helpers
//
//extension EpisodeRow {
//    private var title: some View {
//        HStack(alignment: .top, spacing: 8) {
//            Text(data.episode.title)
//                .frame(maxWidth: .infinity, alignment: .leading)
//                .multilineTextAlignment(.leading)
//
//            if data.isPlaying {
//                Image(systemName: "play.circle.fill")
//            }
//        }
//    }
//
//    @ViewBuilder
//    private var transeffering: some View {
//        let (iconName, text, color) = switch data.transferringState {
//        case .inProgress: ("arrow.trianglehead.2.clockwise.rotate.90.circle.fill", L10n.transferring, Asset.Colors.warning.swiftUIColor)
//        case .finished: ("checkmark.circle.fill", L10n.transferred, Asset.Colors.success.swiftUIColor)
//        }
//
//        HStack {
//            Image(systemName: iconName)
//            Text(verbatim: text)
//        }
//        .font(.footnote)
//        .foregroundColor(color)
//    }
//}
//
//// MARK: - Data
//
//extension EpisodeRow {
//    struct Data: Hashable, Equatable {
//        let episode: EpisodeCommon
//        let isPlaying: Bool
//        let transferringState: TransferringState
//    }
//
//    enum TransferringState: Hashable, Equatable {
//        case inProgress
//        case finished
//    }
//}
