import SwiftUI

struct MembersView: View {
    @EnvironmentObject private var store: DataStore
    @State private var isPresentingAdd: Bool = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.members) { member in
                    VStack(alignment: .leading) {
                        Text(member.name).font(.headline)
                        Text(member.relation).font(.subheadline).foregroundColor(.secondary)
                    }
                }
                .onDelete(perform: delete)
            }
            .navigationTitle("Семья")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isPresentingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isPresentingAdd) {
                AddMemberView { name, relation in
                    let new = FamilyMember(name: name, relation: relation)
                    store.members.append(new)
                    store.save()
                }
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        store.members.remove(atOffsets: offsets)
        store.assignments.removeAll { assignment in
            !store.members.contains { $0.id == assignment.memberId }
        }
        store.save()
    }
}

struct AddMemberView: View {
    var onSave: (String, String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var relation: String = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Имя", text: $name)
                TextField("Отношение (мама, сын...)", text: $relation)
            }
            .navigationTitle("Новый член семьи")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Сохранить") {
                        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        onSave(name, relation)
                        dismiss()
                    }
                }
            }
        }
    }
}

