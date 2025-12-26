//
//  Networking.swift
//  Audstreamer
//
//  Created by Németh Barna on 2020. 12. 08..
//

import Foundation

import Combine

protocol Networking {
    func getEpisodes(from date: Date?) -> AnyPublisher<[Episode], Error>
    func addDevice(with notificationToken: String) -> AnyPublisher<Void, Error>
    func deleteDevice() -> AnyPublisher<Void, Error>
}
