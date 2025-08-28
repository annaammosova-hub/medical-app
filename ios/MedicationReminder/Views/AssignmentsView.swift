import SwiftUI

struct AssignmentsView: View {
    @EnvironmentObject private var store: DataStore
    @State private var isPresentingAdd: Bool = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.assignments) { assignment in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(memberName(for: assignment)).font(.headline)
                            Text(medicationLine(for: assignment)).font(.subheadline).foregroundColor(.secondary)
                            Text(timesLine(for: assignment)).font(.footnote).foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: binding(for: assignment))
                            .labelsHidden()
                            .onChange(of: assignment.isActive) { _ in
                                schedule()
                            }
                    }
                }
                .onDelete(perform: delete)
            }
            .navigationTitle("Расписание")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { isPresentingAdd = true } label: { Image(systemName: "plus") }
                }
                ToolbarItem(placement: .bottomBar) {
                    Button("Перепланировать уведомления") { schedule() }
                }
            }
            .sheet(isPresented: $isPresentingAdd) {
                AddAssignmentView()
            }
        }
    }

    private func binding(for assignment: Assignment) -> Binding<Bool> {
        guard let idx = store.assignments.firstIndex(where: { $0.id == assignment.id }) else {
            return .constant(assignment.isActive)
        }
        return Binding(get: { store.assignments[idx].isActive }, set: { newValue in
            store.assignments[idx].isActive = newValue
            store.save()
        })
    }

    private func schedule() {
        NotificationService.shared.scheduleNotifications(assignments: store.assignments, members: store.members, medications: store.medications)
    }

    private func delete(at offsets: IndexSet) {
        store.assignments.remove(atOffsets: offsets)
        store.save()
        schedule()
    }

    private func memberName(for assignment: Assignment) -> String {
        store.members.first(where: { $0.id == assignment.memberId })?.name ?? "?"
    }

    private func medicationLine(for assignment: Assignment) -> String {
        guard let med = store.medications.first(where: { $0.id == assignment.medicationId }) else { return "?" }
        return "\(med.name) — \(med.dosage)"
    }

    private func timesLine(for assignment: Assignment) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm"
        let calendar = Calendar.current
        let times = assignment.schedule.times.compactMap { comps -> String? in
            calendar.date(from: comps).map { fmt.string(from: $0) }
        }
        return times.joined(separator: ", ")
    }
}

struct AddAssignmentView: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.dismiss) private var dismiss

    @State private var selectedMemberId: UUID?
    @State private var selectedMedicationId: UUID?
    @State private var selectedTimes: [Date] = []

    var body: some View {
        NavigationStack {
            Form {
                Section("Член семьи") {
                    Picker("Кто", selection: Binding(get: {
                        selectedMemberId ?? store.members.first?.id
                    }, set: { selectedMemberId = $0 })) {
                        ForEach(store.members) { member in
                            Text(member.name).tag(member.id as UUID?)
                        }
                    }
                }

                Section("Лекарство") {
                    Picker("Что", selection: Binding(get: {
                        selectedMedicationId ?? store.medications.first?.id
                    }, set: { selectedMedicationId = $0 })) {
                        ForEach(store.medications) { med in
                            Text(med.name).tag(med.id as UUID?)
                        }
                    }
                }

                Section("Время приёма") {
                    ForEach(selectedTimes.indices, id: \.self) { idx in
                        DatePicker("Время \(idx + 1)", selection: Binding(get: {
                            selectedTimes[idx]
                        }, set: { selectedTimes[idx] = $0 }), displayedComponents: .hourAndMinute)
                    }
                    Button("Добавить время") {
                        selectedTimes.append(Date())
                    }
                    if !selectedTimes.isEmpty {
                        Button("Убрать последнее время", role: .destructive) {
                            _ = selectedTimes.popLast()
                        }
                    }
                }
            }
            .navigationTitle("Новое назначение")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Сохранить") {
                        guard let memberId = selectedMemberId ?? store.members.first?.id,
                              let medicationId = selectedMedicationId ?? store.medications.first?.id,
                              !selectedTimes.isEmpty else { return }
                        let calendar = Calendar.current
                        let comps: [DateComponents] = selectedTimes.map { date in
                            calendar.dateComponents([.hour, .minute], from: date)
                        }
                        let schedule = MedicationSchedule(
                            frequency: .customTimes,
                            times: comps,
                            startDate: Date(),
                            endDate: nil
                        )
                        let new = Assignment(memberId: memberId, medicationId: medicationId, schedule: schedule, isActive: true)
                        store.assignments.append(new)
                        store.save()
                        NotificationService.shared.scheduleNotifications(assignments: store.assignments, members: store.members, medications: store.medications)
                        dismiss()
                    }
                }
            }
        }
    }
}

