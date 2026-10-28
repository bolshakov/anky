import AnkyDomain
import Foundation
import Testing

struct EntryKindTests {
    @Test func offersPainStiffnessAndFatigueInThatOrder() {
        #expect(EntryKind.allCases == [.pain, .stiffness, .fatigue])
    }

    @Test func encodesAsItsRawValue() throws {
        let data = try JSONEncoder().encode(EntryKind.pain)
        #expect(String(data: data, encoding: .utf8) == "\"pain\"")
    }
}
