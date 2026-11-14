// SPDX-License-Identifier: GPL-3.0-or-later
import Foundation

enum AddDestination: Equatable { case newEntry, logDose, basdai }

struct AddAction: Identifiable {
    let title: LocalizedStringResource
    let symbol: String
    let destination: AddDestination
    let id: String

    static let all: [AddAction] = [
        AddAction(
            title: "Log how you feel",
            symbol: "square.and.pencil",
            destination: .newEntry,
            id: "log-entry"
        ),
        AddAction(
            title: "Log dose",
            symbol: "pills",
            destination: .logDose,
            id: "log-medication"
        ),
        AddAction(
            title: "BASDAI",
            symbol: "list.bullet.clipboard",
            destination: .basdai,
            id: "add-basdai"
        ), // swiftlint:disable:this trailing_comma
    ]

    static func destination(forID id: String) -> AddDestination? {
        all.first { $0.id == id }?.destination
    }
}
