// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct AboutBlock: View {
    private let version: String
    private let build: String

    init(bundle: Bundle = .main) {
        version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
    }

    var body: some View {
        VStack(spacing: Spacing.tightGap) {
            Image("AnkyMark")
                .resizable()
                .scaledToFit()
                .frame(width: Spacing.aboutMarkWidth)
                .foregroundStyle(Color.tint)
                .padding(.bottom, Spacing.inlineGap)
                .accessibilityHidden(true)
            Text(verbatim: "Anky")
                .font(.headline)
                .foregroundStyle(Color.ink)
            Text("Version \(version) (\(build))")
                .accessibilityIdentifier("settings-version")
            Text(verbatim: "© \(CopyrightYears.text()) Tëma Bolshakov")
            Text("Anky comes with no warranty. You may share and change it under the GNU GPL, version 3 or later.")
                .padding(.top, Spacing.inlineGap)
        }
        .font(.footnote)
        .foregroundStyle(Color.ink2)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("settings-about")
    }
}
