// swift-tools-version:4.1
//
//  Package.swift
//  CommandLineKit
//
//  Build targets by calling the Swift Package Manager in the following way for debug purposes:
//  swift build -Xswiftc "-target" -Xswiftc "x86_64-apple-macosx10.11"
//
//  A release can be built with these options:
//  swift build -c release -Xswiftc -static-stdlib -Xswiftc "-target" -Xswiftc "x86_64-apple-macosx10.11"
//
//  Created by Matthias Zenger on 06/05/2017.
//  Copyright © 2018 Google LLC
//
//  Use of this source code is governed by a BSD-style
//  license that can be found in the LICENSE file or at
//  https://developers.google.com/open-source/licenses/bsd
//

import PackageDescription

let package = Package(
  name: "CommandLineKit",
  products: [
    .library(name: "CommandLineKit", targets: ["CommandLineKit"]),
    .executable(name: "CommandLineKitDemo", targets: ["CommandLineKitDemo"])
  ],
  dependencies: [
  ],
  targets: [
    .target(name: "CommandLineKit",
            dependencies: []),
    .target(name: "CommandLineKitDemo",
            dependencies: ["CommandLineKit"],
            exclude: []),
    .testTarget(name: "CommandLineKitTests",
                dependencies: ["CommandLineKit"])
  ]
)
