// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import Foundation
import Testing

struct DoseNotificationContentTests {
    private let bodyKey = "Time for your dose."

    private func notification(named name: String) -> DoseNotification {
        DoseNotification(medicationID: UUID(), medicationName: name, fireAt: Date(timeIntervalSince1970: 1_900_000_000))
    }

    @Test(arguments: ["Methotrexate", "Vitamin D 5%", "100% Ибупрофен", "Café Ünïcode", "  Padded name  "])
    func theTitleIsTheNameAsTyped(name: String) {
        let content = DoseNotificationContent(notification(named: name), body: bodyKey)
        #expect(content.title == name)
    }

    @Test func theBodyIsTheGivenString() {
        let content = DoseNotificationContent(notification(named: "Walk A"), body: "Any words")
        #expect(content.body == "Any words")
    }

    @Test func theBodyKeyReadsInEnglishAndRussian() throws {
        try CompiledCatalog.withBundle("en") { en in
            #expect(en.localizedString(forKey: bodyKey, value: nil, table: nil) == "Time for your dose.")
        }
        try CompiledCatalog.withBundle("ru") { ru in
            #expect(ru.localizedString(forKey: bodyKey, value: nil, table: nil) == "Пора принять лекарство.")
        }
    }
}
