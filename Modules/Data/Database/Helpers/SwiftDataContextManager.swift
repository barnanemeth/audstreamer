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

    // MARK: Constants

    private enum Constant {
        static let isStoredInMemoryOnly = false
        static let cloudKitDatabase: ModelConfiguration.CloudKitDatabase = .none
    }
}

// MARK: - Static methods

extension SwiftDataContextManager {
    static func instantiate() -> Self {
        do {
            let schema = Schema([PodcastDataModel.self, EpisodeDataModel.self])

            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: Constant.isStoredInMemoryOnly,
                cloudKitDatabase: Constant.cloudKitDatabase
            )
            print("Model container URL", configuration.url)
            return Self(modelContainer: try ModelContainer(for: schema, configurations: [configuration]))
        } catch {
            fatalError("Cannot create ModelContainer")
        }
    }
}


// MARK: - Internal methods

extension SwiftDataContextManager {
    func fetch<Model: PersistentModel>(_ descriptor: FetchDescriptor<Model>) throws -> [Model] {
        try modelContext.fetch(descriptor)
    }

    func fetchIdentifiers<Model: PersistentModel>(_ descriptor: FetchDescriptor<Model>) throws -> [PersistentIdentifier] {
        try modelContext.fetchIdentifiers(descriptor)
    }

    func insert<Model: PersistentModel & Identifiable>(_ models: [Model], ignoreIfExists: Bool) throws {
        try modelContext.transaction {
            let modelsToInsert: [Model]
            if ignoreIfExists {
                var descriptor = FetchDescriptor<Model>()
                descriptor.propertiesToFetch = [\.id]

                let existingIDs = try modelContext.fetch(descriptor).map(\.id)

                modelsToInsert = models.lazy.filter { !existingIDs.contains($0.id) }
            } else {
                modelsToInsert = models
            }

            modelsToInsert.forEach { model in
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
        try modelContext.save()

        // Note: workaround
        NotificationCenter.default.post(
            name: ModelContext.didSave,
            object: modelContext,
            userInfo: [:]
        )
    }

    func transaction(_ block: () -> Void) throws {
        try modelContext.transaction {
            block()
        }
    }

    func mapDataModel<DataModelType: PersistentModel & DomainMappable>(_ model: DataModelType?) -> DataModelType.DomainModelType? {
        model?.asDomainModel
    }

    func mapDataModel<DataModelType: PersistentModel & APIMappable>(_ model: DataModelType?) -> DataModelType.APIModelType? {
        model?.asAPIModel
    }

    func mapDataModels<DataModelType: PersistentModel & DomainMappable>(_ models: [DataModelType]) -> [DataModelType.DomainModelType] {
        models.compactMap { mapDataModel($0) }
    }

    func mapDataModels<DataModelType: PersistentModel & APIMappable>(_ models: [DataModelType]) -> [DataModelType.APIModelType] {
        models.compactMap { mapDataModel($0) }
    }

    func mapDataModels<DataModelType: PersistentModel, Output>(_ models: [DataModelType], block: (DataModelType) -> Output) -> [Output] {
        models.compactMap { model in
            block(model)
        }
    }
}
