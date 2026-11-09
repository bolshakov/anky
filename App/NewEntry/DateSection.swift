// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct DateSection: View {
    @Binding var date: Date
    private let onOpen: () -> Void
    @State private var isShowingPicker = false

    init(date: Binding<Date>, onOpen: @escaping () -> Void = {}) {
        _date = date
        self.onOpen = onOpen
    }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                isShowingPicker.toggle()
                if isShowingPicker {
                    onOpen()
                }
            } label: {
                HStack {
                    Text("Date and time")
                    Spacer()
                    Text(verbatim: "\(day), \(clock)")
                        .foregroundStyle(Color.ink2)
                    RowChevron()
                }
                .rowHeight()
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("date-row")
            .accessibilityLabel("Date and time")
            .accessibilityValue(Text([day, clock].joined(separator: " ")))
            if isShowingPicker {
                DatePicker(
                    "Date and time",
                    selection: $date,
                    in: ...Date.now,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .padding(.bottom, Spacing.inlineGap)
                .accessibilityIdentifier("date-picker")
            }
        }
        .fillsCardRow()
    }

    private var day: String {
        switch ShortDayText.day(for: date, now: .now, calendar: .current, locale: .current) {
        case .today:
            String(localized: "Today")
        case .yesterday:
            String(localized: "Yesterday")
        case let .sameYear(shortDay):
            shortDay
        case let .otherYear(shortDay, year):
            "\(shortDay) \(year)"
        }
    }

    private var clock: String {
        ClockText.text(for: date, calendar: .current, locale: .current)
    }
}
