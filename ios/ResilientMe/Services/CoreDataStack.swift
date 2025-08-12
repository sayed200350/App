import Foundation
import CoreData

final class CoreDataStack {
    static let shared = CoreDataStack()

    let persistentContainer: NSPersistentContainer

    private init() {
        let model = CoreDataStack.makeModel()
        persistentContainer = NSPersistentContainer(name: "ResilientMe", managedObjectModel: model)
        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data store failed to load: \(error)")
            }
            self.persistentContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        }
    }

    var context: NSManagedObjectContext { persistentContainer.viewContext }

    func saveIfNeeded() {
        guard context.hasChanges else { return }
        do { try context.save() } catch { print("Core Data save error: \(error)") }
    }

    func newBackgroundContext() -> NSManagedObjectContext {
        let ctx = persistentContainer.newBackgroundContext()
        ctx.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return ctx
    }

    // MARK: - Model
    private static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // Entity: RejectionCD
        let entity = NSEntityDescription()
        entity.name = "RejectionCD"
        entity.managedObjectClassName = "NSManagedObject"

        var properties: [NSAttributeDescription] = []

        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.attributeType = .UUIDAttributeType
        idAttr.isOptional = false
        properties.append(idAttr)

        let typeAttr = NSAttributeDescription()
        typeAttr.name = "type"
        typeAttr.attributeType = .stringAttributeType
        typeAttr.isOptional = false
        properties.append(typeAttr)

        let impactAttr = NSAttributeDescription()
        impactAttr.name = "emotionalImpact"
        impactAttr.attributeType = .doubleAttributeType
        impactAttr.isOptional = false
        properties.append(impactAttr)

        let noteAttr = NSAttributeDescription()
        noteAttr.name = "note"
        noteAttr.attributeType = .stringAttributeType
        noteAttr.isOptional = true
        properties.append(noteAttr)

        let timestampAttr = NSAttributeDescription()
        timestampAttr.name = "timestamp"
        timestampAttr.attributeType = .dateAttributeType
        timestampAttr.isOptional = false
        properties.append(timestampAttr)

        let locationAttr = NSAttributeDescription()
        locationAttr.name = "location"
        locationAttr.attributeType = .stringAttributeType
        locationAttr.isOptional = true
        properties.append(locationAttr)

        let imageDataAttr = NSAttributeDescription()
        imageDataAttr.name = "imageData"
        imageDataAttr.attributeType = .binaryDataAttributeType
        imageDataAttr.isOptional = true
        properties.append(imageDataAttr)

        let isRecoveredAttr = NSAttributeDescription()
        isRecoveredAttr.name = "isRecovered"
        isRecoveredAttr.attributeType = .booleanAttributeType
        isRecoveredAttr.isOptional = false
        isRecoveredAttr.defaultValue = false
        properties.append(isRecoveredAttr)

        let recoveryTimeAttr = NSAttributeDescription()
        recoveryTimeAttr.name = "recoveryTime"
        recoveryTimeAttr.attributeType = .doubleAttributeType
        recoveryTimeAttr.isOptional = false
        recoveryTimeAttr.defaultValue = 0.0
        properties.append(recoveryTimeAttr)

        entity.properties = properties
        model.entities = [entity]
        return model
    }
}


