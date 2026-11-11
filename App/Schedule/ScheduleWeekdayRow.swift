// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

struct ScheduleWeekdayRow: View {
    let weekdays: Set<Locale.Weekday>
    let onTap: (Locale.Weekday) -> Void

    private let calendar = Calendar.current

    var body: some View {
        HStack(spacing: 0) {
            ForEach(orderedWeekdays, id: \.self) { weekday in
                WeekdayColumn(
                    weekday: weekday,
                    letter: calendar.veryShortStandaloneWeekdaySymbols[weekday.symbolIndex],
                    name: calendar.standaloneWeekdaySymbols[weekday.symbolIndex],
                    isChosen: weekdays.contains(weekday)
                ) {
                    onTap(weekday)
                }
            }
        }
        .padding(.horizontal, Spacing.weekdayRowPadding)
        .frame(height: Spacing.weekdayRowHeight)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("schedule-weekdays")
    }

    private var orderedWeekdays: [Locale.Weekday] {
        let first = calendar.firstWeekday - 1
        return (0 ..< 7).map { Locale.Weekday.inSymbolOrder[(first + $0) % 7] }
    }
}

private struct WeekdayColumn: View {
    let weekday: Locale.Weekday
    let letter: String
    let name: String
    let isChosen: Bool
    let tap: () -> Void

    var body: some View {
        Button(action: tap) {
            VStack(spacing: Spacing.tightGap) {
                Text(letter)
                    .font(.system(size: Spacing.weekdayLetterSize))
                    .foregroundStyle(isChosen ? Color.onTint : Color.ink)
                    .frame(width: Spacing.weekdayChosenCircle, height: Spacing.weekdayChosenCircle)
                    .background {
                        if isChosen {
                            Circle().fill(Color.tint)
                        }
                    }
                Circle()
                    .fill(Color.ink2)
                    .frame(width: Spacing.weekdayDot, height: Spacing.weekdayDot)
                    .opacity(isChosen ? 0 : 1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .frame(minWidth: Spacing.tapTarget)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(name)
        .accessibilityAddTraits(isChosen ? .isSelected : [])
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
