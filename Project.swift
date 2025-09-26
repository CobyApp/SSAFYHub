import ProjectDescription

let project = Project(
  name: "SSAFYHub",
  targets: [
    .target(
      name: "SharedModels",
      destinations: .iOS,
      product: .framework,
      bundleId: "com.coby.ssafyhub.sharedmodels",
      deploymentTargets: .iOS("17.0"),
      infoPlist: .default,
      sources: ["SharedModels/Sources/**"],
      dependencies: [],
      settings: .settings(base: [
        "DEVELOPMENT_TEAM": "3Y8YH8GWMM",
        "TARGETED_DEVICE_FAMILY": "1"
      ])
    ),

    .target(
      name: "SSAFYHub",
      destinations: .iOS,
      product: .app,
      bundleId: "com.coby.ssafyhub",
      deploymentTargets: .iOS("17.0"),
      infoPlist: .extendingDefault(with: [
        "CFBundleDisplayName": "SSAFYHub",
        "CFBundleName": "SSAFYHub",
        "CFBundleVersion": "8",
        "CFBundleShortVersionString": "1.0.6",
        "CFBundleDevelopmentRegion": "ko",
        "CFBundleLocalizations": ["ko"],
        "NSCameraUsageDescription": "메뉴 사진을 촬영하여 OCR로 메뉴를 인식하기 위해 카메라 접근 권한이 필요합니다.",
        "NSPhotoLibraryUsageDescription": "앨범에서 메뉴 사진을 선택하여 OCR로 메뉴를 인식하기 위해 사진 접근 권한이 필요합니다.",
        "UIApplicationSceneManifest": [
          "UIApplicationSupportsMultipleScenes": false,
          "UISceneConfigurations": [
            "UIWindowSceneSessionRoleApplication": [
              ["UISceneConfigurationName": "Default Configuration"]
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
        .external(name: "ComposableArchitecture"),
        .external(name: "Dependencies"),
        .external(name: "IdentifiedCollections"),
        .target(name: "SSAFYHubWidget")
      ],
      settings: .settings(base: [
        "DEVELOPMENT_TEAM": "3Y8YH8GWMM",
        "TARGETED_DEVICE_FAMILY": "1"
      ])
    ),

    .target(
      name: "SSAFYHubTests",
      destinations: .iOS,
      product: .unitTests,
      bundleId: "com.coby.ssafyhub.Tests",
      deploymentTargets: .iOS("17.0"),
      infoPlist: .default,
      sources: ["SSAFYHub/Tests/**"],
      dependencies: [.target(name: "SSAFYHub")]
    ),

    .target(
      name: "SSAFYHubWidget",
      destinations: .iOS,
      product: .appExtension,
      productName: "SSAFYHubWidget",
      bundleId: "com.coby.ssafyhub.widget",
      deploymentTargets: .iOS("17.0"),
      infoPlist: .extendingDefault(with: [
        "CFBundleDisplayName": "SSAFYHub 식단 위젯",
        "CFBundleName": "SSAFYHub 식단 위젯",
        "CFBundleDevelopmentRegion": "ko",
        "CFBundleLocalizations": ["ko"],
        "CFBundleVersion": "8",
        "CFBundleShortVersionString": "1.0.6",
        "CFBundlePackageType": "XPC!",
        "CFBundleInfoDictionaryVersion": "6.0",
        "NSExtension": [
          "NSExtensionPointIdentifier": "com.apple.widgetkit-extension"
        ],
        "NSWidgetWantsLocation": false,
        "NSWidgetAllowsEditing": true,
        "NSWidgetDisplayMode": "Expanded",
        "NSWidgetSupportedFamilies": [
          "com.apple.widget.system.small",
          "com.apple.widget.system.medium"
        ]
      ]),
      sources: ["SSAFYHubWidget/Sources/**"],
      resources: ["SSAFYHubWidget/Resources/**"],
      entitlements: "SSAFYHubWidget/SSAFYHubWidget.entitlements",
      dependencies: [
        .target(name: "SharedModels"),
        .external(name: "Supabase")
      ],
      settings: .settings(base: [
        "DEVELOPMENT_TEAM": "3Y8YH8GWMM",
        "TARGETED_DEVICE_FAMILY": "1",
        "CODE_SIGN_ALLOW_ENTITLEMENTS_MODIFICATION": "YES"
      ])
    )
  ]
)