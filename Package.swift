// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "SwiftUseCase",
    platforms: [
        .macOS("10.15"),
        .iOS("13.0"),
        .tvOS("13.0"),
        .watchOS("6.0")
    ],
    products: [
        .library(name: "SwiftUseCase", targets: ["SwiftUseCase"]),
    ],
    targets: [
        .target(
            name: "SwiftUseCase",
            path: "Sources"
        ),
        .testTarget(name: "SwiftUseCaseTests", dependencies: ["SwiftUseCase"], path: "Tests"),
    ]
)
