// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Testing

struct EntryKindTests {
    @Test func offersPainStiffnessAndFatigueInThatOrder() {
        #expect(EntryKind.allCases == [.pain, .stiffness, .fatigue])
    }
}
