//
//  DomainMappable.swift
//  Data
//
//  Created by Barna Nemeth on 2026. 01. 16..
//

import Foundation

protocol DomainMappable {
    associatedtype DomainModelType

    var asDomainModel: DomainModelType? { get }
}

protocol DataMappable {
    associatedtype DataModelType

    var asDataModel: DataModelType? { get }
}

protocol APIMappable {
    associatedtype APIModelType

    var asAPIModel: APIModelType? { get }
}

extension Array where Element: DomainMappable {
    var asDomainModels: [Element.DomainModelType] {
        compactMap { $0.asDomainModel }
    }
}

extension Array where Element: DataMappable {
    var asDomainModels: [Element.DataModelType] {
        compactMap { $0.asDataModel }
    }
}

extension Array where Element: APIMappable {
    var asDomainModels: [Element.APIModelType] {
        compactMap { $0.asAPIModel }
    }
}
