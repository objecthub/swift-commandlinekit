# Swift CommandLineKit

[![Platform: macOS](https://img.shields.io/badge/Platform-macOS-blue.svg?style=flat)](https://developer.apple.com/osx/)
[![Language: Swift 4.1](https://img.shields.io/badge/Language-Swift%204.1-green.svg?style=flat)](https://developer.apple.com/swift/)
[![IDE: Xcode 9.3](https://img.shields.io/badge/IDE-Xcode%209.3-orange.svg?style=flat)](https://developer.apple.com/xcode/)
[![Carthage: compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![License: BSD](https://img.shields.io/badge/License-BSD-lightgrey.svg?style=flat)](https://developers.google.com/open-source/licenses/bsd)

## Overview

This is a library supporting the development of command-line tools in
the programming language Swift on macOS. The library provides the following
functionality:

   - Management of command-line arguments
   - Usage of escape sequences in XTerms
   - Reading strings on terminals using a lineread-inspired implementation
     based on the library [Linenoise-Swift](https://github.com/andybest/linenoise-swift),
     but supporting unicode input, multiple lines, and styled text.

## Requirements

   - XCode 9.3
   - Swift 4.1
   - Carthage or Swift Package Manager
