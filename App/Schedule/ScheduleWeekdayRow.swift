// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

struct ScheduleWeekdayRow: View {
    @Binding var weekdays: Set<Locale.Weekday>
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private let calendar = Calendar.current

    var body: some View {
        let buttons = ForEach(orderedWeekdays, id: \.self) { weekday in
            WeekdayButton(
                weekday: weekday,
                symbol: calendar.veryShortStandaloneWeekdaySymbols[weekday.symbolIndex],
                name: calendar.standaloneWeekdaySymbols[weekday.symbolIndex],
                isOn: weekdays.contains(weekday)
            ) {
                weekdays.formSymmetricDifference([weekday])
            }
        }
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: Spacing.inlineGap) {
                    buttons
                }
            } else {
                HStack(spacing: Spacing.inlineGap) { buttons }
            }
        }
        .padding(.vertical, Spacing.tightGap)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("schedule-weekdays")
    }

    private var orderedWeekdays: [Locale.Weekday] {
        let first = calendar.firstWeekday - 1
        return (0 ..< 7).map { Locale.Weekday.inSymbolOrder[(first + $0) % 7] }
    }
}

private struct WeekdayButton: View {
    let weekday: Locale.Weekday
    let symbol: String
    let name: String
    let isOn: Bool
    let toggle: () -> Void

    var body: some View {
        Button(action: toggle) {
            Text(symbol)
                .frame(maxWidth: .infinity, minHeight: Spacing.tapTarget)
        }
        .buttonStyle(.borderless)
        .foregroundStyle(isOn ? Color.onTint : Color.ink)
        .background(isOn ? Color.tint : Color.fill, in: .capsule)
        .contentShape(.capsule)
        .accessibilityLabel(name)
        .accessibilityValue(isOn ? Text("on") : Text("off"))
        .accessibilityAddTraits(.isToggle)
        .accessibilityIdentifier("weekday-\(weekday.idSuffix)")
    }
}

private extension Locale.Weekday {
    static let inSymbolOrder: [Locale.Weekday] = [.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday]

    var symbolIndex: Int {
        Self.inSymbolOrder.firstIndex(of: self) ?? 0
    }

    var idSuffix: String {
        ["sun", "mon", "tue", "wed", "thu", "fri", "sat"][symbolIndex]
    }
}
