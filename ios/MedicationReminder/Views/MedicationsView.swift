import SwiftUI

struct MedicationsView: View {
    @EnvironmentObject private var store: DataStore
    @State private var isPresentingAdd: Bool = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.medications) { med in
                    VStack(alignment: .leading) {
                        Text(med.name).font(.headline)
                        Text(med.dosage).font(.subheadline).foregroundColor(.secondary)
                        if let notes = med.notes, !notes.isEmpty {
                            Text(notes).font(.footnote).foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete(perform: delete)
            }
            .navigationTitle("Лекарства")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { isPresentingAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $isPresentingAdd) {
                AddMedicationView { name, dosage, notes in
                    let new = Medication(name: name, dosage: dosage, notes: notes)
                    store.medications.append(new)
                    store.save()
                }
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        store.medications.remove(atOffsets: offsets)
        store.assignments.removeAll { assignment in
            !store.medications.contains { $0.id == assignment.medicationId }
        }
        store.save()
    }
}

struct AddMedicationView: View {
    var onSave: (String, String, String?) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var dosage: String = ""
    @State private var notes: String = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Название", text: $name)
                TextField("Дозировка (например, 1 таблетка)", text: $dosage)
                TextField("Примечания", text: $notes)
            }
            .navigationTitle("Новое лекарство")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Сохранить") {
                        guard !name.trimmingCharacters(in: .whitespaces).isEmpty,
                              !dosage.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                        let n = notes.trimmingCharacters(in: .whitespaces)
                        onSave(name, dosage, n.isEmpty ? nil : n)
                        dismiss()
                    }
                }
            }
        }
    }
}

