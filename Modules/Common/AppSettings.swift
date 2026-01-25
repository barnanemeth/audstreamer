//
//  AppSettings.swift
//  Common
//
//  Created by Barna Nemeth on 2026. 01. 19..
//

import Foundation

public enum AppSettings {
    static let isDev = false

    public static var apiBaseURL: URL {
        if isDev {
            "http://10.10.0.194:4000"
        } else {
            "https://api.audstreamer.com"
        }
    }

    public static var apiURL: URL {
        if isDev {
            Self.apiBaseURL.appending(path: "api")
        } else {
            Self.apiBaseURL
        }
    }

    public static var socketBaseURL: URL {
        if isDev {
            "http://localhost:4000"
        } else {
            "https://socket.audstreamer.com"
        }
    }

    public static var socketPath: String {
        if isDev {
            "/socket"
        } else {
            "/"
        }
    }

    public static var apiKey: String {
        "66d9b38b-2736-4035-b6c5-643ffb30615a"
    }
}
