import SwiftUI

@main
struct MedicationReminderApp: App {
    @StateObject private var dataStore: DataStore = DataStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(dataStore)
                .onAppear {
                    NotificationService.shared.requestAuthorization()
                }
        }
    }
}

