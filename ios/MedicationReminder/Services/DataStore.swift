import Foundation

final class DataStore: ObservableObject {
    @Published var members: [FamilyMember] = []
    @Published var medications: [Medication] = []
    @Published var assignments: [Assignment] = []
    @Published var doseLogs: [DoseLogEntry] = []

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
        var doseLogs: [DoseLogEntry]
    }

    func load() {
        do {
            let data = try Data(contentsOf: persistenceURL)
            let decoded = try JSONDecoder().decode(Snapshot.self, from: data)
            self.members = decoded.members
            self.medications = decoded.medications
            self.assignments = decoded.assignments
            self.doseLogs = decoded.doseLogs
        } catch {
            // initialize with sample data on first launch
            self.members = []
            self.medications = []
            self.assignments = []
            self.doseLogs = []
            save()
        }
    }

    func save() {
        let snapshot = Snapshot(members: members, medications: medications, assignments: assignments, doseLogs: doseLogs)
        do {
            let data = try JSONEncoder().encode(snapshot)
            try data.write(to: persistenceURL, options: .atomic)
        } catch {
            print("Failed to save: \(error)")
        }
    }

    // MARK: - Dose helpers

    func dateKey(for date: Date) -> String {
        let fmt = DateFormatter()
        fmt.calendar = Calendar.current
        fmt.locale = .current
        fmt.timeZone = .current
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.string(from: date)
    }

    private func logIndex(dateKey: String, assignmentId: UUID, hour: Int, minute: Int) -> Int? {
        doseLogs.firstIndex { $0.dateKey == dateKey && $0.assignmentId == assignmentId && $0.hour == hour && $0.minute == minute }
    }

    func statusFor(assignmentId: UUID, hour: Int, minute: Int, on date: Date) -> (DoseStatus, Date?) {
        let key = dateKey(for: date)
        if let entry = doseLogs.first(where: { $0.dateKey == key && $0.assignmentId == assignmentId && $0.hour == hour && $0.minute == minute }) {
            return (entry.status, entry.snoozeUntil)
        }
        return (.pending, nil)
    }

    func updateDoseStatus(assignmentId: UUID, date: Date, hour: Int, minute: Int, status: DoseStatus, snoozeUntil: Date? = nil) {
        let key = dateKey(for: date)
        if let idx = logIndex(dateKey: key, assignmentId: assignmentId, hour: hour, minute: minute) {
            doseLogs[idx].status = status
            doseLogs[idx].snoozeUntil = snoozeUntil
        } else {
            let entry = DoseLogEntry(dateKey: key, assignmentId: assignmentId, hour: hour, minute: minute, status: status, snoozeUntil: snoozeUntil)
            doseLogs.append(entry)
        }
        save()
    }

    func resolvedDoses(for date: Date) -> [ResolvedDose] {
        let key = dateKey(for: date)
        let calendar = Calendar.current
        let memberById = Dictionary(uniqueKeysWithValues: members.map { ($0.id, $0) })
        let medById = Dictionary(uniqueKeysWithValues: medications.map { ($0.id, $0) })

        var results: [ResolvedDose] = []
        for assignment in assignments where assignment.isActive {
            guard let member = memberById[assignment.memberId], let med = medById[assignment.medicationId] else { continue }
            for comps in assignment.schedule.times {
                let hour = comps.hour ?? 0
                let minute = comps.minute ?? 0
                var dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
                dateComponents.hour = hour
                dateComponents.minute = minute
                guard let dateTime = calendar.date(from: dateComponents) else { continue }
                let (status, snoozeUntil) = statusFor(assignmentId: assignment.id, hour: hour, minute: minute, on: date)
                let dose = ResolvedDose(dateKey: key, assignment: assignment, member: member, medication: med, hour: hour, minute: minute, dateTime: dateTime, status: status, snoozeUntil: snoozeUntil)
                results.append(dose)
            }
        }
        return results.sorted { a, b in a.dateTime < b.dateTime }
    }
}

