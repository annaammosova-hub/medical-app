import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            MembersView()
                .tabItem {
                    Label("Семья", systemImage: "person.3")
                }

            MedicationsView()
                .tabItem {
                    Label("Лекарства", systemImage: "pills")
                }

            AssignmentsView()
                .tabItem {
                    Label("Расписание", systemImage: "calendar")
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

