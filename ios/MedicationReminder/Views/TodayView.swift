import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var store: DataStore
    @State private var showingAddAssignment: Bool = false
    @State private var now: Date = Date()

    private var todayDoses: [ResolvedDose] {
        store.resolvedDoses(for: now)
    }

    private var nextDose: ResolvedDose? {
        let upcoming = todayDoses.filter { dose in
            switch dose.status {
            case .pending, .snoozed: return true
            case .taken, .skipped: return false
            }
        }
        .sorted { a, b in
            let aTime = a.snoozeUntil ?? a.dateTime
            let bTime = b.snoozeUntil ?? b.dateTime
            return aTime < bTime
        }
        return upcoming.first
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    nextDoseCard
                    scheduleSections
                    infoBanners
                }
                .padding()
            }
            .navigationBarHidden(true)
            .onAppear { now = Date() }
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("FamilyMed").font(.title).bold()
                Text(dateString(now)).font(.subheadline).foregroundColor(.secondary)
            }
            Spacer()
            Button { showingAddAssignment = true } label: { Image(systemName: "plus.circle.fill").font(.title2) }
                .padding(.trailing, 12)
            Button { /* open missed doses center (stub) */ } label: { Image(systemName: "bell.fill").font(.title2) }
        }
        .sheet(isPresented: $showingAddAssignment) {
            AddAssignmentView()
                .environmentObject(store)
        }
    }

    private var nextDoseCard: some View {
        Group {
            if let dose = nextDose {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ближайший приём")
                        .font(.headline)
                    HStack(alignment: .center, spacing: 12) {
                        avatar(for: dose.member)
                        VStack(alignment: .leading) {
                            Text(dose.medication.name).font(.headline)
                            Text(dose.member.name).font(.subheadline).foregroundColor(.secondary)
                            Text(timeLabel(for: dose)).font(.subheadline)
                            Text(dose.medication.dosage).font(.footnote).foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    HStack(spacing: 8) {
                        Button { mark(dose, as: .taken) } label: {
                            Label("Принято", systemImage: "checkmark")
                        }
                        .buttonStyle(.borderedProminent)

                        Menu {
                            Button("Отложить на 10 мин") { snooze(dose, minutes: 10) }
                            Button("Отложить на 15 мин") { snooze(dose, minutes: 15) }
                            Button("Отложить на 30 мин") { snooze(dose, minutes: 30) }
                        } label: {
                            Label("Отложить", systemImage: "alarm")
                        }
                        .buttonStyle(.bordered)

                        Button(role: .destructive) { mark(dose, as: .skipped) } label: {
                            Label("Пропустить", systemImage: "xmark")
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            } else {
                VStack(alignment: .leading) {
                    Text("На сегодня запланированных приёмов нет").foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
        }
    }

    private var scheduleSections: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Сегодня").font(.headline)
            ForEach(timeSections(), id: \.title) { section in
                if !section.doses.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(section.title).font(.subheadline).foregroundColor(.secondary)
                        ForEach(section.doses) { dose in
                            DoseRow(dose: dose, onAction: { action in
                                switch action {
                                case .taken: mark(dose, as: .taken)
                                case .skipped: mark(dose, as: .skipped)
                                case .snooze(let mins): snooze(dose, minutes: mins)
                                }
                            })
                        }
                    }
                }
            }
        }
    }

    private var infoBanners: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Optional contextual banners (stock/course). Stub for now.
        }
    }

    private func dateString(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEE, MMM d"
        fmt.locale = Locale(identifier: Locale.preferredLanguages.first ?? "ru_RU")
        return fmt.string(from: date)
    }

    private func avatar(for member: FamilyMember) -> some View {
        let initials = member.name.split(separator: " ").compactMap { $0.first }.prefix(2)
        let text = String(initials)
        return ZStack {
            Circle().fill(Color.blue.opacity(0.2))
            Text(text).foregroundColor(.blue).bold()
        }
        .frame(width: 44, height: 44)
    }

    private func timeLabel(for dose: ResolvedDose) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm"
        if let snooze = dose.snoozeUntil, snooze > now {
            return "Отложено до " + fmt.string(from: snooze)
        }
        return fmt.string(from: dose.dateTime)
    }

    private func mark(_ dose: ResolvedDose, as status: DoseStatus) {
        store.updateDoseStatus(assignmentId: dose.assignment.id, date: now, hour: dose.hour, minute: dose.minute, status: status)
    }

    private func snooze(_ dose: ResolvedDose, minutes: Int) {
        let fire = Date().addingTimeInterval(TimeInterval(minutes * 60))
        store.updateDoseStatus(assignmentId: dose.assignment.id, date: now, hour: dose.hour, minute: dose.minute, status: .snoozed, snoozeUntil: fire)
        NotificationService.shared.scheduleSnooze(assignmentId: dose.assignment.id, memberName: dose.member.name, medication: dose.medication, fireDate: fire)
    }

    private struct SectionData { let title: String; let doses: [ResolvedDose] }

    private func timeSections() -> [SectionData] {
        let doses = todayDoses
        let morning = doses.filter { (5...10).contains($0.hour) }
        let afternoon = doses.filter { (11...16).contains($0.hour) }
        let evening = doses.filter { (17...21).contains($0.hour) }
        let night = doses.filter { ($0.hour >= 22) || ($0.hour <= 4) }
        return [
            SectionData(title: "Утро", doses: morning),
            SectionData(title: "День", doses: afternoon),
            SectionData(title: "Вечер", doses: evening),
            SectionData(title: "Ночь", doses: night)
        ]
    }
}

private enum DoseRowAction { case taken; case skipped; case snooze(Int) }

private struct DoseRow: View {
    let dose: ResolvedDose
    let onAction: (DoseRowAction) -> Void
    @State private var isExpanded: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 12) {
                avatar
                VStack(alignment: .leading) {
                    Text(dose.medication.name)
                    Text(dose.medication.dosage).font(.footnote).foregroundColor(.secondary)
                }
                Spacer()
                Text(timeLabel).font(.footnote)
                statusDot
            }
            if isExpanded {
                HStack(spacing: 8) {
                    Button { onAction(.taken) } label: { Label("Принято", systemImage: "checkmark") }
                        .buttonStyle(.borderedProminent)
                    Menu {
                        Button("10 мин") { onAction(.snooze(10)) }
                        Button("15 мин") { onAction(.snooze(15)) }
                        Button("30 мин") { onAction(.snooze(30)) }
                    } label: { Label("Отложить", systemImage: "alarm") }
                    .buttonStyle(.bordered)
                    Button(role: .destructive) { onAction(.skipped) } label: { Label("Пропустить", systemImage: "xmark") }
                        .buttonStyle(.bordered)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .onTapGesture { withAnimation { isExpanded.toggle() } }
    }

    private var avatar: some View {
        let initials = dose.member.name.split(separator: " ").compactMap { $0.first }.prefix(2)
        let text = String(initials)
        return ZStack { Circle().fill(Color.blue.opacity(0.2)); Text(text).foregroundColor(.blue).bold() }
            .frame(width: 36, height: 36)
    }

    private var statusDot: some View {
        let color: Color = {
            switch dose.status {
            case .taken: return .green
            case .snoozed: return .yellow
            case .skipped: return .red
            case .pending: return .gray
            }
        }()
        return Circle().fill(color).frame(width: 10, height: 10)
    }

    private var timeLabel: String {
        let fmt = DateFormatter(); fmt.dateFormat = "HH:mm"
        if let snooze = dose.snoozeUntil, snooze > Date() {
            return fmt.string(from: snooze)
        }
        return String(format: "%02d:%02d", dose.hour, dose.minute)
    }
}

