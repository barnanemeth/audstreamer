//
//  AudioPlayeError.swift
//  Audstreamer
//
//  Created by Barna Nemeth on 2026. 01. 02..
//

public enum AudioPlayeError: Error {
    case missingResource
    case cannotLoadAsset(Error?)
    case cannotActivate
}
