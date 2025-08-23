// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SSAFYHub",
    platforms: [.iOS(.v17)],
    products: [],
    dependencies: [
        .package(url: "https://github.com/supabase/supabase-swift.git", from: "2.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture.git", from: "1.22.1"),
        .package(url: "https://github.com/pointfreeco/swift-dependencies.git", from: "1.2.0"),
        .package(url: "https://github.com/pointfreeco/swift-identified-collections.git", from: "1.1.0")
    ],
    targets: []
)