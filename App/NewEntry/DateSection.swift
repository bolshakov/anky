// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

struct DateSection: View {
    @Binding var date: Date

    var body: some View {
        DatePicker(
            "Date and time",
            selection: $date,
            in: ...Date.now,
            displayedComponents: [.date, .hourAndMinute]
        )
        .datePickerStyle(.compact)
    }
}
