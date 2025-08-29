import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("Сегодня", systemImage: "sun.max")
                }

            CalendarView()
                .tabItem {
                    Label("Календарь", systemImage: "calendar")
                }

            MembersView()
                .tabItem {
                    Label("Семья", systemImage: "person.3")
                }

            MedicationsView()
                .tabItem {
                    Label("Лекарства", systemImage: "pills")
                }

            ShoppingView()
                .tabItem {
                    Label("Покупки", systemImage: "cart")
                }
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
            .environmentObject(DataStore())
    }
}

