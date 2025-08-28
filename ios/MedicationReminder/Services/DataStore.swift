import Foundation

final class DataStore: ObservableObject {
    @Published var members: [FamilyMember] = []
    @Published var medications: [Medication] = []
    @Published var assignments: [Assignment] = []

    private let persistenceURL: URL

    init() {
        self.persistenceURL = DataStore.defaultPersistenceURL()
        load()
    }

    static func defaultPersistenceURL() -> URL {
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("medication_data.json")
    }

    struct Snapshot: Codable {
        var members: [FamilyMember]
        var medications: [Medication]
        var assignments: [Assignment]
    }

    func load() {
        do {
            let data = try Data(contentsOf: persistenceURL)
            let decoded = try JSONDecoder().decode(Snapshot.self, from: data)
            self.members = decoded.members
            self.medications = decoded.medications
            self.assignments = decoded.assignments
        } catch {
            // initialize with sample data on first launch
            self.members = []
            self.medications = []
            self.assignments = []
            save()
        }
    }

    func save() {
        let snapshot = Snapshot(members: members, medications: medications, assignments: assignments)
        do {
            let data = try JSONEncoder().encode(snapshot)
            try data.write(to: persistenceURL, options: .atomic)
        } catch {
            print("Failed to save: \(error)")
        }
    }
}

