// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "KovaleeAttribution",
	defaultLocalization: "en",
	platforms: [
		.iOS(.v14)
	],
    products: [
		.library(
			name: "KovaleeAttribution",
			targets: [
				"KovaleeAttribution",
			]
		)
    ],
    dependencies: [
		.package(url: "https://github.com/cotyapps/Kovalee-iOS-SDK", branch: "sdk-spm-split"),
		.package(url: "https://github.com/adjust/ios_sdk", from: Version(4, 33, 5))
    ],
    targets: [
		.target(
			name: "KovaleeAttribution",
			dependencies: [
				.product(name: "KovaleeSDK", package: "Kovalee-iOS-SDK"),
				.product(name: "Adjust", package: "ios_sdk")
			]
		)
    ]
)
