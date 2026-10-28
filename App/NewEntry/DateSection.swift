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
                    shownDate
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
        .background(Color("CardBackground"), in: .card)
    }

    private var shownDate: Text {
        let day = Calendar.current.isDateInToday(draft.date)
            ? Text("Today")
            : Text(draft.date, format: Date.FormatStyle(date: .abbreviated, time: .omitted))
        let time = Text(draft.date, format: .dateTime.hour(.twoDigits(amPM: .abbreviated)).minute(.twoDigits))
        return Text("\(day), \(time)")
    }
}
