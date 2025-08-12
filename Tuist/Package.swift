// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SSAFYHub",
    platforms: [.iOS(.v17)],
    products: [],
    dependencies: [
        .package(url: "https://github.com/supabase/supabase-swift.git", from: "2.0.0")
    ],
    targets: []
)