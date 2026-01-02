// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
public enum L10n {
  /// Account
  public static let account = L10n.tr("Localizable", "account", fallback: "Account")
  /// All downloads are completed
  public static let allDownloadsCompleted = L10n.tr("Localizable", "allDownloadsCompleted", fallback: "All downloads are completed")
  /// Sign in to your Apple ID if you want to use cross-device synchronization
  public static let appleIDRequired = L10n.tr("Localizable", "appleIDRequired", fallback: "Sign in to your Apple ID if you want to use cross-device synchronization")
  /// Barna Nemeth
  public static let authorName = L10n.tr("Localizable", "authorName", fallback: "Barna Nemeth")
  /// Bad API status
  public static let badAPIStatus = L10n.tr("Localizable", "badAPIStatus", fallback: "Bad API status")
  /// Bad response format
  public static let badResponseFormat = L10n.tr("Localizable", "badResponseFormat", fallback: "Bad response format")
  /// Cancel
  public static let cancel = L10n.tr("Localizable", "cancel", fallback: "Cancel")
  /// Connect
  public static let connect = L10n.tr("Localizable", "connect", fallback: "Connect")
  /// Connected
  public static let connected = L10n.tr("Localizable", "connected", fallback: "Connected")
  /// Continue
  public static let `continue` = L10n.tr("Localizable", "continue", fallback: "Continue")
  /// © %@ %@
  public static func copyright(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "copyright", String(describing: p1), String(describing: p2), fallback: "© %@ %@")
  }
  /// Delete
  public static let delete = L10n.tr("Localizable", "delete", fallback: "Delete")
  /// Delete downloads
  public static let deleteDownloads = L10n.tr("Localizable", "deleteDownloads", fallback: "Delete downloads")
  /// Are you sure to delete downloaded episodes?
  public static let deleteDownloadsConfirm = L10n.tr("Localizable", "deleteDownloadsConfirm", fallback: "Are you sure to delete downloaded episodes?")
  /// Devices
  public static let devices = L10n.tr("Localizable", "devices", fallback: "Devices")
  /// Disconnect
  public static let disconnect = L10n.tr("Localizable", "disconnect", fallback: "Disconnect")
  /// Disconnected
  public static let disconnected = L10n.tr("Localizable", "disconnected", fallback: "Disconnected")
  /// Download
  public static let download = L10n.tr("Localizable", "download", fallback: "Download")
  /// Using data over a cellular network may occur additional fees.
  public static let downloadCellularWarningMessage = L10n.tr("Localizable", "downloadCellularWarningMessage", fallback: "Using data over a cellular network may occur additional fees.")
  /// Error: %@
  public static func downloadError(_ p1: Any) -> String {
    return L10n.tr("Localizable", "downloadError", String(describing: p1), fallback: "Error: %@")
  }
  /// Finished
  public static let downloadFinished = L10n.tr("Localizable", "downloadFinished", fallback: "Finished")
  /// Downloading
  public static let downloading = L10n.tr("Localizable", "downloading", fallback: "Downloading")
  /// Plural format key: "Downloading %#@format@ (%d%%)"
  public static func downloadingEpisodesCountPercentage(_ p1: Int, _ p2: Int) -> String {
    return L10n.tr("Localizable", "downloadingEpisodesCountPercentage", p1, p2, fallback: "Plural format key: \"Downloading %#@format@ (%d%%)\"")
  }
  /// In progress
  public static let downloadInProgress = L10n.tr("Localizable", "downloadInProgress", fallback: "In progress")
  /// Paused
  public static let downloadPaused = L10n.tr("Localizable", "downloadPaused", fallback: "Paused")
  /// Queued
  public static let downloadQueued = L10n.tr("Localizable", "downloadQueued", fallback: "Queued")
  /// Downloads
  public static let downloads = L10n.tr("Localizable", "downloads", fallback: "Downloads")
  /// Plural format key: "Size of the downloadable %#@format@ is %@."
  public static func downloadSize(_ p1: Int, _ p2: Any) -> String {
    return L10n.tr("Localizable", "downloadSize", p1, String(describing: p2), fallback: "Plural format key: \"Size of the downloadable %#@format@ is %@.\"")
  }
  /// Downloads: **%@**
  public static func downloadsSize(_ p1: Any) -> String {
    return L10n.tr("Localizable", "downloadsSize", String(describing: p1), fallback: "Downloads: **%@**")
  }
  /// Duration
  /// %@
  public static func duration(_ p1: Any) -> String {
    return L10n.tr("Localizable", "duration", String(describing: p1), fallback: "Duration\n%@")
  }
  /// Error
  public static let error = L10n.tr("Localizable", "error", fallback: "Error")
  /// Favorite
  public static let favorite = L10n.tr("Localizable", "favorite", fallback: "Favorite")
  /// Favorites
  public static let favorites = L10n.tr("Localizable", "favorites", fallback: "Favorites")
  /// Later on Wi-Fi
  public static let laterOnWifi = L10n.tr("Localizable", "laterOnWifi", fallback: "Later on Wi-Fi")
  /// Listening on **%@**
  public static func listeningOn(_ p1: Any) -> String {
    return L10n.tr("Localizable", "listeningOn", String(describing: p1), fallback: "Listening on **%@**")
  }
  /// Loading
  public static let loading = L10n.tr("Localizable", "loading", fallback: "Loading")
  /// Sign in
  public static let logIn = L10n.tr("Localizable", "logIn", fallback: "Sign in")
  /// If you signed in, you are able to use real-time handoff service.
  public static let logInInfo = L10n.tr("Localizable", "logInInfo", fallback: "If you signed in, you are able to use real-time handoff service.")
  /// Sign out
  public static let logout = L10n.tr("Localizable", "logout", fallback: "Sign out")
  /// Are you sure to want to log out?
  public static let logoutConfirm = L10n.tr("Localizable", "logoutConfirm", fallback: "Are you sure to want to log out?")
  /// Audstreamer
  public static let mainTitle = L10n.tr("Localizable", "mainTitle", fallback: "Audstreamer")
  /// New episode
  public static let newEpisode = L10n.tr("Localizable", "newEpisode", fallback: "New episode")
  /// New episodes
  public static let newEpisodes = L10n.tr("Localizable", "newEpisodes", fallback: "New episodes")
  /// New episodes available
  public static let newEpisodesAreAvailable = L10n.tr("Localizable", "newEpisodesAreAvailable", fallback: "New episodes available")
  /// No results
  public static let noResults = L10n.tr("Localizable", "noResults", fallback: "No results")
  /// Localizable.strings
  ///   Audstreamer
  /// 
  ///   Created by Németh Barna on 2020. 12. 08..
  public static let ok = L10n.tr("Localizable", "ok", fallback: "OK")
  /// On Watch
  public static let onWatch = L10n.tr("Localizable", "onWatch", fallback: "On Watch")
  /// Pending
  public static let pending = L10n.tr("Localizable", "pending", fallback: "Pending")
  /// Play
  public static let play = L10n.tr("Localizable", "play", fallback: "Play")
  /// Play last played episode
  public static let playLastPlayedEpisode = L10n.tr("Localizable", "playLastPlayedEpisode", fallback: "Play last played episode")
  /// Play newest episode
  public static let playNewestEpisode = L10n.tr("Localizable", "playNewestEpisode", fallback: "Play newest episode")
  /// Publish date
  /// %@
  public static func publishDate(_ p1: Any) -> String {
    return L10n.tr("Localizable", "publishDate", String(describing: p1), fallback: "Publish date\n%@")
  }
  /// Retry
  public static let retry = L10n.tr("Localizable", "retry", fallback: "Retry")
  /// Settings
  public static let settings = L10n.tr("Localizable", "settings", fallback: "Settings")
  /// Share
  public static let share = L10n.tr("Localizable", "share", fallback: "Share")
  /// Sign in with Apple
  public static let signInWithApple = L10n.tr("Localizable", "signInWithApple", fallback: "Sign in with Apple")
  /// Socket
  public static let socket = L10n.tr("Localizable", "socket", fallback: "Socket")
  /// Storage
  public static let storage = L10n.tr("Localizable", "storage", fallback: "Storage")
  /// Transferring
  public static let transferring = L10n.tr("Localizable", "transferring", fallback: "Transferring")
  /// Plural format key: "Transferring %#@format@ (%d%%)"
  public static func transferringEpisodesCountPercentage(_ p1: Int, _ p2: Int) -> String {
    return L10n.tr("Localizable", "transferringEpisodesCountPercentage", p1, p2, fallback: "Plural format key: \"Transferring %#@format@ (%d%%)\"")
  }
  /// Unacceptable HTTP status (%d)
  public static func unacceptableStatus(_ p1: Int) -> String {
    return L10n.tr("Localizable", "unacceptableStatus", p1, fallback: "Unacceptable HTTP status (%d)")
  }
  /// Version %@ (%@)
  public static func version(_ p1: Any, _ p2: Any) -> String {
    return L10n.tr("Localizable", "version", String(describing: p1), String(describing: p2), fallback: "Version %@ (%@)")
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg..., fallback value: String) -> String {
    let format = BundleToken.bundle.localizedString(forKey: key, value: value, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
