import Foundation
import CoreData

final class RejectionManager: ObservableObject {
    static let shared = RejectionManager()

    private init() {}

    private let context: NSManagedObjectContext = CoreDataStack.shared.context

    func save(entry: RejectionEntry) {
        let bg = CoreDataStack.shared.newBackgroundContext()
        bg.perform {
            let object = NSEntityDescription.insertNewObject(forEntityName: "RejectionCD", into: bg)
            object.setValue(entry.id, forKey: "id")
            object.setValue(entry.type.rawValue, forKey: "type")
            object.setValue(entry.emotionalImpact, forKey: "emotionalImpact")
            object.setValue(entry.note, forKey: "note")
            object.setValue(entry.timestamp, forKey: "timestamp")
            object.setValue(nil, forKey: "location")
            object.setValue(nil, forKey: "imageData")
            object.setValue(false, forKey: "isRecovered")
            object.setValue(0.0, forKey: "recoveryTime")
            do { try bg.save() } catch { print("Core Data save error: \(error)") }
        }

        // Firestore sync via repository (non-blocking)
        FirestoreSyncService.shared.save(entry: entry)
    }

    func delete(id: UUID) {
        let bg = CoreDataStack.shared.newBackgroundContext()
        bg.perform {
            let request = NSFetchRequest<NSManagedObject>(entityName: "RejectionCD")
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            if let results = try? bg.fetch(request) {
                for obj in results { bg.delete(obj) }
                do { try bg.save() } catch { print("Core Data delete error: \(error)") }
            }
        }
    }

    func recent(days: Int) -> [RejectionEntry] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let request = NSFetchRequest<NSManagedObject>(entityName: "RejectionCD")
        request.predicate = NSPredicate(format: "timestamp >= %@", cutoff as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        do {
            let results = try context.fetch(request)
            return results.compactMap { obj in
                guard let id = obj.value(forKey: "id") as? UUID,
                      let typeString = obj.value(forKey: "type") as? String,
                      let type = RejectionType(rawValue: typeString),
                      let ts = obj.value(forKey: "timestamp") as? Date
                else { return nil }
                let impact = obj.value(forKey: "emotionalImpact") as? Double ?? 0
                let note = obj.value(forKey: "note") as? String
                return RejectionEntry(id: id, type: type, emotionalImpact: impact, note: note, timestamp: ts, imageUrl: nil)
            }
        } catch {
            print("Core Data fetch error: \(error)")
            return []
        }
    }

    func recentHighImpact(threshold: Double = 7) -> [RejectionEntry] {
        recent(days: 7).filter { $0.emotionalImpact >= threshold }
    }
}


