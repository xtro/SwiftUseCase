// swift-tools-version:5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription
import CompilerPluginSupport

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
        .library(name: "SwiftUseCaseMacro", targets: ["SwiftUseCaseMacro"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "510.0.0")
    ],
    targets: [
        .macro(
            name: "Macros",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ],
            path: "Sources/Macros"
        ),
        .target(
            name: "SwiftUseCaseMacro",
            dependencies: ["Macros"],
            path: "Sources/Plugin"
        ),
        .target(
            name: "SwiftUseCase",
            dependencies: ["SwiftUseCaseMacro"],
            path: "Sources/Usecases"
        ),
        .testTarget(name: "SwiftUseCaseTests", dependencies: ["SwiftUseCase"], path: "Tests"),
    ]
)
