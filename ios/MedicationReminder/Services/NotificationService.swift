import Foundation
import UserNotifications

final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()

    private override init() { }

    func requestAuthorization() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification authorization error: \(error)")
            }
            print("Notification authorization granted: \(granted)")
        }
    }

    func scheduleNotifications(assignments: [Assignment], members: [FamilyMember], medications: [Medication]) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        let memberById = Dictionary(uniqueKeysWithValues: members.map { ($0.id, $0) })
        let medById = Dictionary(uniqueKeysWithValues: medications.map { ($0.id, $0) })

        for assignment in assignments where assignment.isActive {
            guard let member = memberById[assignment.memberId], let med = medById[assignment.medicationId] else { continue }

            for time in assignment.schedule.times {
                var dateComponents = time
                let content = UNMutableNotificationContent()
                content.title = "Прием лекарства"
                content.body = "\(member.name): \(med.name) — \(med.dosage)"
                content.sound = .default

                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                let id = "assignment_\(assignment.id.uuidString)_\(time.hour ?? 0)_\(time.minute ?? 0)"
                let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                center.add(request) { error in
                    if let error = error {
                        print("Failed to schedule notification: \(error)")
                    }
                }
            }
        }
    }

    // Foreground presentation
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}

