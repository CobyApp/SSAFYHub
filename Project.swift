import ProjectDescription

let project = Project(
    name: "SSAWorld",
    targets: [
        .target(
            name: "SSAWorld",
            destinations: .iOS,
            product: .app,
            bundleId: "dev.tuist.SSAWorld",
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                ]
            ),
            sources: ["SSAWorld/Sources/**"],
            resources: ["SSAWorld/Resources/**"],
            dependencies: []
        ),
        .target(
            name: "SSAWorldTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.tuist.SSAWorldTests",
            infoPlist: .default,
            sources: ["SSAWorld/Tests/**"],
            resources: [],
            dependencies: [.target(name: "SSAWorld")]
        ),
    ]
)
