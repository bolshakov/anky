// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct ScheduleTimesSection: View {
    @Binding var schedule: ScheduleDraft
    @State private var rowIDs: [UUID]

    init(schedule: Binding<ScheduleDraft>) {
        _schedule = schedule
        _rowIDs = State(initialValue: schedule.wrappedValue.times.map { _ in UUID() })
    }

    var body: some View {
        CardSection(Text("Times"), id: "schedule-times") {
            ForEach(Array(zip(rowIDs, schedule.times.indices)), id: \.0) { _, index in
                DatePicker(selection: time(at: index), displayedComponents: .hourAndMinute) {
                    Text("Time")
                }
                .datePickerStyle(.compact)
                .foregroundStyle(Color.ink)
                .rowHeight()
                .accessibilityIdentifier("schedule-time-\(index + 1)")
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    if schedule.times.count > 1 {
                        Button("Delete", systemImage: "trash", role: .destructive) { remove(at: index) }
                    }
                }
            }
            Button(action: addTime) {
                Text("Add a time").foregroundStyle(Color.tint)
            }
            .rowHeight()
            .accessibilityIdentifier("schedule-add-time")
        }
    }

    private func time(at index: Int) -> Binding<Date> {
        Binding(
            get: { schedule.times[safe: index].map(ScheduleClock.date) ?? .now },
            set: { picked in
                if let time = ScheduleClock.time(of: picked), schedule.times.indices.contains(index) {
                    schedule.times[index] = time
                }
            }
        )
    }

    private func addTime() {
        let before = schedule.times.count
        schedule.addTime()
        if schedule.times.count > before {
            rowIDs.append(UUID())
        }
    }

    private func remove(at index: Int) {
        let before = schedule.times.count
        schedule.removeTime(at: index)
        if schedule.times.count < before {
            rowIDs.remove(at: index)
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

/// A picker holds a `Date`, so a time is placed on one fixed day. A daylight-saving day then never moves the hour.
private enum ScheduleClock {
    private static var calendar: Calendar {
        .current
    }

    static func date(_ time: DoseTime) -> Date {
        let parts = DateComponents(year: 2001, month: 1, day: 1, hour: time.hour, minute: time.minute)
        return calendar.date(from: parts) ?? .now
    }

    static func time(of date: Date) -> DoseTime? {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        return DoseTime(hour: parts.hour ?? 0, minute: parts.minute ?? 0)
    }
}
