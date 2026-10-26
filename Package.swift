// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Anky",
    platforms: [.macOS(.v14), .iOS(.v18)],
    products: [
        .library(name: "AnkyDomain", targets: ["AnkyDomain"]),
    ],
    targets: [
        .target(name: "AnkyDomain"),
        .target(name: "AnkyData", dependencies: ["AnkyDomain"]),
        .testTarget(name: "AnkyDomainTests", dependencies: ["AnkyDomain"]),
    ]
)
