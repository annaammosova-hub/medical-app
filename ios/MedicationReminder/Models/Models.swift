import Foundation

struct FamilyMember: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var relation: String
}

struct Medication: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var dosage: String
    var notes: String?
}

enum ScheduleFrequency: String, Codable, CaseIterable {
    case daily
    case weekly
    case customTimes // specific times per day
}

struct MedicationSchedule: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var frequency: ScheduleFrequency
    var times: [DateComponents] // hours/minutes for reminders
    var startDate: Date
    var endDate: Date?
}

struct Assignment: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var memberId: UUID
    var medicationId: UUID
    var schedule: MedicationSchedule
    var isActive: Bool
}

enum DoseStatus: String, Codable, CaseIterable, Hashable {
    case pending
    case taken
    case snoozed
    case skipped
}

struct DoseLogEntry: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var dateKey: String // yyyy-MM-dd for local day
    var assignmentId: UUID
    var hour: Int
    var minute: Int
    var status: DoseStatus
    var snoozeUntil: Date?
}

struct ResolvedDose: Identifiable, Hashable {
    // Unique id per assignment+time for a specific date key
    var id: String { "\(dateKey)_\(assignment.id.uuidString)_\(hour)_\(minute)" }
    let dateKey: String
    let assignment: Assignment
    let member: FamilyMember
    let medication: Medication
    let hour: Int
    let minute: Int
    let dateTime: Date
    var status: DoseStatus
    var snoozeUntil: Date?
}

