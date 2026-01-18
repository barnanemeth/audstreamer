//
//  SwiftDataContextManager.swift
//  Data
//
//  Created by Barna Nemeth on 2026. 01. 06..
//

import Foundation
import SwiftData

@ModelActor
actor SwiftDataContextManager {
    func fetch<Model: PersistentModel>(_ descriptor: FetchDescriptor<Model>) throws -> [Model] {
        try modelContext.fetch(descriptor)
    }

    func insert<Model: PersistentModel>(_ models: [Model]) throws {
        try modelContext.transaction {
            models.forEach { model in
                modelContext.insert(model)
            }
        }
    }

    func delete<Model: PersistentModel>(_ models: [Model]) throws {
        try modelContext.transaction {
            models.forEach { model in
                modelContext.delete(model)
            }
        }
    }

    func delete<Model: PersistentModel>(where predicate: Predicate<Model>) throws {
        try modelContext.delete(model: Model.self, where: predicate)
    }

    func transaction(_ block: () -> Void) throws {
        try modelContext.transaction {
            block()
        }
    }
}
