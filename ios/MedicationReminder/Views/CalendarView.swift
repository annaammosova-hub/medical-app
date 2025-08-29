import SwiftUI

struct CalendarView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Text("Календарь (скоро)")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Календарь")
        }
    }
}

