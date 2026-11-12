// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct ScheduleDurationSection: View {
    @Binding var schedule: ScheduleDraft
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        CardSection(Text("Duration"), footnote: footnote, id: "schedule-duration", footnoteID: "schedule-footnote") {
            DatePicker(selection: starts, displayedComponents: .date) {
                Text("Starts")
            }
            .datePickerStyle(.compact)
            .foregroundStyle(Color.ink)
            .rowHeight()
            .accessibilityIdentifier("schedule-starts")
            if let end = schedule.end {
                setEndRow(end)
            } else {
                noEndRow
            }
        }
    }

    private var footnote: Text? {
        schedule.schedule().map {
            Text(verbatim: MedicationScheduleLine.footnote(
                schedule: $0, now: .now, locale: .current, calendar: .current, bundle: .main
            ))
        }
    }

    private var noEndRow: some View {
        HStack {
            Text("Ends").foregroundStyle(Color.ink)
            Spacer()
            Button {
                schedule.setEnd(schedule.start)
            } label: {
                Text("None").foregroundStyle(Color.ink)
            }
            .buttonStyle(.bordered)
            .tint(Color.ink2)
        }
        .rowHeight()
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("schedule-ends")
    }

    private func setEndRow(_ end: ScheduleDay) -> some View {
        setEndLayout {
            DatePicker(
                selection: ends(end),
                in: ScheduleCalendar.date(schedule.start)...,
                displayedComponents: .date
            ) {
                Text("Ends")
            }
            .datePickerStyle(.compact)
            .foregroundStyle(Color.ink)
            .accessibilityIdentifier("schedule-ends")
            Button {
                schedule.setEnd(nil)
            } label: {
                Image(systemName: "xmark.circle.fill").foregroundStyle(Color.ink2).minimumTapTarget()
            }
            .buttonStyle(.plain)
            .accessibilityLabel("None")
            .accessibilityIdentifier("schedule-ends-clear")
        }
        .rowHeight()
    }

    /// At accessibility sizes the compact picker's pill alone fills the card's width, so the × goes below it.
    private var setEndLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading)) : AnyLayout(HStackLayout())
    }

    private var starts: Binding<Date> {
        Binding(
            get: { ScheduleCalendar.date(schedule.start) },
            set: { schedule.setStart(ScheduleCalendar.day($0)) }
        )
    }

    private func ends(_ end: ScheduleDay) -> Binding<Date> {
        Binding(
            get: { ScheduleCalendar.date(end) },
            set: { schedule.setEnd(ScheduleCalendar.day($0)) }
        )
    }
}

private enum ScheduleCalendar {
    private static var calendar: Calendar {
        .current
    }

    static func date(_ day: ScheduleDay) -> Date {
        calendar.date(from: DateComponents(year: day.year, month: day.month, day: day.day)) ?? .now
    }

    static func day(_ date: Date) -> ScheduleDay {
        ScheduleDay(date, in: calendar.timeZone)
    }
}
