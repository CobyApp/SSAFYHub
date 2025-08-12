// swift-tools-version: 5.10
import PackageDescription

#if TUIST
    import struct ProjectDescription.PackageSettings

    let packageSettings = PackageSettings(
        // Customize the product types for specific package product
        // Default is .staticFramework
        // productTypes: ["Alamofire": .framework,]
        productTypes: [:]
    )
#endif

let package = Package(
    name: "SSAWorld",
    dependencies: [
        // Supabase
        .package(url: "https://github.com/supabase-community/supabase-swift.git", from: "2.0.0"),
    ]
)