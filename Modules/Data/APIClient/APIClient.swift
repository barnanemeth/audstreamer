//
//  APIClient.swift
//  Audstreamer
//
//  Created by Németh Barna on 2020. 12. 08..
//

import Foundation
import Combine

import Domain

protocol APIClient {
    func getEpisodes(from date: Date?) -> AnyPublisher<[Episode], Error>
    func addDevice(with notificationToken: String) -> AnyPublisher<Void, Error>
    func deleteDevice() -> AnyPublisher<Void, Error>
}
