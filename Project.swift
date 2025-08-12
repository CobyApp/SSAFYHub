import ProjectDescription

let project = Project(
    name: "SSAWorld",
    targets: [
        .target(
            name: "SSAWorld",
            destinations: .iOS,
            product: .app,
            bundleId: "com.coby.ssaworld",
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                    "CFBundleURLTypes": [
                        [
                            "CFBundleURLName": "com.coby.ssaworld",
                            "CFBundleURLSchemes": ["com.coby.ssaworld"]
                        ]
                    ],
                    "NSCameraUsageDescription": "식단 사진을 촬영하여 메뉴를 자동으로 인식합니다.",
                    "NSPhotoLibraryUsageDescription": "앨범에서 식단 사진을 선택하여 메뉴를 자동으로 인식합니다.",
                    "CFBundleDisplayName": "SSAFY 점심식단",
                    "CFBundleName": "SSAFY 점심식단"
                ]
            ),
            sources: ["SSAWorld/Sources/**"],
            resources: ["SSAWorld/Resources/**"],
            dependencies: [
                .external(name: "Supabase")
            ],
            settings: .settings(
                base: [
                    "DEVELOPMENT_TEAM": "3Y8YH8GWMM",
                    "TARGETED_DEVICE_FAMILY": "1" // iPhone만 지원 (1: iPhone, 2: iPad, 1,2: iPhone + iPad)
                ]
            )
        ),
        .target(
            name: "SSAWorldTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.coby.ssaworldTests",
            infoPlist: .default,
            sources: ["SSAWorld/Tests/**"],
            resources: [],
            dependencies: [.target(name: "SSAWorld")],
            settings: .settings(
                base: [
                    "DEVELOPMENT_TEAM": "3Y8YH8GWMM"
                ]
            )
        ),
    ]
)
