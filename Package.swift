// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "UICBarcodeKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "UICBarcodeKit", targets: ["UICBarcodeKit"]),
    ],
    targets: [
        .target(
            name: "UICBarcodeKit",
            path: "UICBarcodeKit/Sources/UICBarcodeKit"
        ),
        .testTarget(
            name: "UICBarcodeKitTests",
            dependencies: ["UICBarcodeKit"],
            path: "UICBarcodeKit/Tests/UICBarcodeKitTests"
        ),
    ]
)
