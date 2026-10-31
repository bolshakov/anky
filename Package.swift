// SPDX-License-Identifier: GPL-3.0-or-later
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Anky",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "AnkyDomain", targets: ["AnkyDomain"]),
        .library(name: "AnkyStore", targets: ["AnkyStore"]),
    ],
    targets: [
        .target(name: "AnkyDomain"),
        .testTarget(name: "AnkyDomainTests", dependencies: ["AnkyDomain"]),
        .target(name: "AnkyStore", dependencies: ["AnkyDomain"]),
        .testTarget(name: "AnkyStoreTests", dependencies: ["AnkyDomain", "AnkyStore"]),
    ]
)
