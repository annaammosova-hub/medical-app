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

