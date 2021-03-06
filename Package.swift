// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ostool",
    dependencies: [
      .package(url: "git@github.com:kylef/Commander.git", from: "0.7.1"),
      .package(url: "git@github.com:ReactiveX/RxSwift.git", .revision("4.0.0-beta.1")),
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "ostool",
            dependencies: ["Commander", "RxSwift", "RxBlocking"]),
    ]
)
