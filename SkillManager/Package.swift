// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "SkillManager",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "SkillManager", targets: ["SkillManager"])
    ],
    dependencies: [
        // No external dependencies - we use only native SQLite3 and SwiftUI
    ],
    targets: [
        .executableTarget(
            name: "SkillManager",
            path: ".",
            exclude: [
                "old-SkillManager.xcodeproj"
            ],
            sources: [
                "App",
                "Models",
                "Services",
                "ViewModels",
                "Views",
            ]
        )
    ]
)
