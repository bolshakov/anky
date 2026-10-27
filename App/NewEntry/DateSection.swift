import AnkyDomain
import SwiftUI

struct DateSection: View {
    @Binding var draft: EntryDraft
    @State private var isShowingPicker = false

    var body: some View {
        VStack(spacing: 0) {
            Button {
                isShowingPicker.toggle()
            } label: {
                HStack {
                    Text("Date and time")
                    Spacer()
                    Text(shownDate)
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
                .padding()
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("date-row")
            .accessibilityLabel("Date and time")
            .accessibilityValue(shownDate)
            if isShowingPicker {
                DatePicker(
                    "Date and time",
                    selection: $draft.date,
                    in: ...Date.now,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .accessibilityIdentifier("date-picker")
            }
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private var shownDate: String {
        let day = Calendar.current.isDateInToday(draft.date)
            ? "Today"
            : draft.date.formatted(date: .abbreviated, time: .omitted)
        // A 24 hour clock, as the wheel shows, whatever the device's language.
        let time = draft.date.formatted(
            .dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits).locale(Locale(identifier: "en_GB"))
        )
        return "\(day), \(time)"
    }
}
