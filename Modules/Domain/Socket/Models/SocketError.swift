//
//  SocketError.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2026. 01. 02..
//

public enum SocketError: Error {
    case connectionError(String?)
    case disconnected
}
