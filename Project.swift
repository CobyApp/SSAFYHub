import ProjectDescription

let project = Project(
    name: "SSAFYHub",
    targets: [
        .target(
            name: "SharedModels",
            destinations: [.iPhone],
            product: .framework,
            productName: "SharedModels",
            bundleId: "com.coby.ssafyhub.sharedmodels",
            infoPlist: .default,
            sources: ["SharedModels/Sources/**"],
            resources: [],
            dependencies: [],
            settings: .settings(
                base: [
                    "DEVELOPMENT_TEAM": "3Y8YH8GWMM",
                    "TARGETED_DEVICE_FAMILY": "1",
                    "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
                    "SUPPORTED_PLATFORMS": "iphoneos",
                    "SUPPORTS_MACCATALYST": "NO",
                    "SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD": "NO"
                ]
            )
        ),
        .target(
            name: "SSAFYHub",
            destinations: [.iPhone],
            product: .app,
            bundleId: "com.coby.ssafyhub",
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": "SSAFYHub",
                "CFBundleName": "SSAFYHub",
                "CFBundleLocalizations": ["ko"],
                "NSCameraUsageDescription": "메뉴 사진을 촬영하여 OCR로 메뉴를 인식하기 위해 카메라 접근 권한이 필요합니다.",
                "NSPhotoLibraryUsageDescription": "앨범에서 메뉴 사진을 선택하여 OCR로 메뉴를 인식하기 위해 사진 접근 권한이 필요합니다.",
                "UIApplicationSceneManifest": [
                    "UIApplicationSupportsMultipleScenes": false,
                    "UISceneConfigurations": [
                        "UIWindowSceneSessionRoleApplication": [
                            [
                                "UISceneConfigurationName": "Default Configuration"
                            ]
                        ]
                    ]
                ],
                "UILaunchScreen": [:],
                "UIStatusBarStyle": "UIStatusBarStyleDefault",
                "UIViewControllerBasedStatusBarAppearance": false
            ]),
            sources: ["SSAFYHub/Sources/**"],
            resources: ["SSAFYHub/Resources/**"],
            entitlements: "SSAFYHub/SSAFYHub.entitlements",
            dependencies: [
                .target(name: "SharedModels"),
                .external(name: "Supabase"),
                .target(name: "SSAFYHubWidget")
            ],
            settings: .settings(
                base: [
                    "DEVELOPMENT_TEAM": "3Y8YH8GWMM",
                    "TARGETED_DEVICE_FAMILY": "1",
                    "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
                    "SUPPORTED_PLATFORMS": "iphoneos",
                    "SUPPORTS_MACCATALYST": "NO",
                    "SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD": "NO",
                    "CODE_SIGN_ALLOW_ENTITLEMENTS_MODIFICATION": "YES"
                ]
            )
        ),
        .target(
            name: "SSAFYHubTests",
            destinations: [.iPhone],
            product: .unitTests,
            bundleId: "com.coby.ssafyhub.Tests",
            infoPlist: .default,
            sources: ["SSAFYHub/Tests/**"],
            resources: [],
            dependencies: [.target(name: "SSAFYHub")],
            settings: .settings(
                base: [
                    "DEVELOPMENT_TEAM": "3Y8YH8GWMM"
                ]
            )
        ),
        .target(
            name: "SSAFYHubWidget",
            destinations: [.iPhone],
            product: .appExtension,
            productName: "SSAFYHubWidget",
            bundleId: "com.coby.ssafyhub.widget",
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": "SSAFYHub 위젯",
                "CFBundleName": "SSAFYHub 위젯",
                "CFBundleVersion": "1.0.0",
                "CFBundleShortVersionString": "1.0.0",
                "CFBundlePackageType": "XPC!",
                "CFBundleInfoDictionaryVersion": "6.0",
                "NSExtension": [
                    "NSExtensionPointIdentifier": "com.apple.widgetkit-extension"
                ],
                "NSWidgetWantsLocation": false,
                "NSWidgetAllowsEditing": true,
                "NSWidgetDisplayMode": "Expanded",
                "NSWidgetSupportedFamilies": ["com.apple.widget.system.small", "com.apple.widget.system.medium"]
            ]),
            sources: ["SSAFYHubWidget/Sources/**"],
            resources: ["SSAFYHubWidget/Resources/**"],
            entitlements: "SSAFYHubWidget/SSAFYHubWidget.entitlements",
            dependencies: [
                .target(name: "SharedModels"),
                .external(name: "Supabase")
            ],
            settings: .settings(
                base: [
                    "DEVELOPMENT_TEAM": "3Y8YH8GWMM",
                    "TARGETED_DEVICE_FAMILY": "1",
                    "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
                    "SUPPORTED_PLATFORMS": "iphoneos",
                    "SUPPORTS_MACCATALYST": "NO",
                    "SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD": "NO",
                    "CODE_SIGN_ALLOW_ENTITLEMENTS_MODIFICATION": "YES",
                    "APPLICATION_EXTENSION_API_ONLY": "YES",
                    "ENABLE_BITCODE": "NO",
                    "SWIFT_VERSION": "5.0",
                    "CLANG_ENABLE_MODULES": "YES",
                    "DEFINES_MODULE": "YES"
                ]
            )
        ),
    ]
)
