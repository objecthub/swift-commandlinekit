//
//  ColorRGBTests.swift
//  CommandLineKitTests
//
//  Created on 30/05/2026.
//  Copyright © 2026 Matthias Zenger. All rights reserved.
//

import XCTest
@testable import CommandLineKit

/// Tests for RGB approximation constructors in TextColor and BackgroundColor
class ColorRGBTests: XCTestCase {
  
  func testTextColorPureRed() {
    let color = TextColor(color: (255, 0, 0), fullColorSupport: false)
    XCTAssertEqual(color, .red)
    XCTAssertFalse(color.isExtended)
  }
  
  func testTextColorPureGreen() {
    let color = TextColor(color: (0, 255, 0), fullColorSupport: false)
    XCTAssertEqual(color, .lime)
    XCTAssertFalse(color.isExtended)
  }
  
  func testTextColorPureBlue() {
    let color = TextColor(color: (0, 0, 255), fullColorSupport: false)
    XCTAssertEqual(color, .blue)
    XCTAssertFalse(color.isExtended)
  }
  
  func testTextColorPureYellow() {
    let color = TextColor(color: (255, 255, 0), fullColorSupport: false)
    XCTAssertEqual(color, .yellow)
    XCTAssertFalse(color.isExtended)
  }
  
  func testTextColorPureWhite() {
    let color = TextColor(color: (255, 255, 255), fullColorSupport: false)
    XCTAssertEqual(color, .white)
    XCTAssertFalse(color.isExtended)
  }
  
  func testTextColorPureBlack() {
    let color = TextColor(color: (0, 0, 0), fullColorSupport: false)
    XCTAssertEqual(color, .black)
    XCTAssertFalse(color.isExtended)
  }
  
  func testTextColorPureCyan() {
    let color = TextColor(color: (0, 255, 255), fullColorSupport: false)
    XCTAssertEqual(color, .aqua)
    XCTAssertFalse(color.isExtended)
  }
  
  func testTextColorPureMagenta() {
    let color = TextColor(color: (255, 0, 255), fullColorSupport: false)
    XCTAssertEqual(color, .fuchsia)
    XCTAssertFalse(color.isExtended)
  }
  
  func testTextColorDarkRed() {
    let color = TextColor(color: (128, 0, 0), fullColorSupport: false)
    XCTAssertEqual(color, .maroon)
    XCTAssertFalse(color.isExtended)
  }
  
  func testTextColorDarkGreen() {
    let color = TextColor(color: (0, 128, 0), fullColorSupport: false)
    XCTAssertEqual(color, .green)
    XCTAssertFalse(color.isExtended)
  }
  
  func testTextColorDarkBlue() {
    let color = TextColor(color: (0, 0, 128), fullColorSupport: false)
    XCTAssertEqual(color, .navy)
    XCTAssertFalse(color.isExtended)
  }
  
  func testTextColorDarkYellow() {
    let color = TextColor(color: (128, 128, 0), fullColorSupport: false)
    XCTAssertEqual(color, .olive)
    XCTAssertFalse(color.isExtended)
  }
  
  func testTextColorDarkCyan() {
    let color = TextColor(color: (0, 128, 128), fullColorSupport: false)
    XCTAssertEqual(color, .teal)
    XCTAssertFalse(color.isExtended)
  }
  
  func testTextColorDarkMagenta() {
    let color = TextColor(color: (128, 0, 128), fullColorSupport: false)
    XCTAssertEqual(color, .purple)
    XCTAssertFalse(color.isExtended)
  }
  
  func testTextColorGray() {
    let color = TextColor(color: (192, 192, 192), fullColorSupport: false)
    XCTAssertEqual(color, .silver)
    XCTAssertFalse(color.isExtended)
  }
  
  func testTextColorDarkGray() {
    let color = TextColor(color: (64, 64, 64), fullColorSupport: false)
    XCTAssertEqual(color, .black)
    XCTAssertFalse(color.isExtended)
  }
  
  func testTextColorExtendedMode() {
    let color = TextColor(color: (123, 45, 67), fullColorSupport: true)
    XCTAssertTrue(color.isExtended)
  }
  
  func testTextColorExtendedModeExactBlack() {
    let color = TextColor(color: (0, 0, 0), fullColorSupport: true)
    // In extended mode, should map to extended color code
    XCTAssertTrue(color.isExtended)
    if case .extended(let code) = color {
      XCTAssertEqual(code, 0) // Black in 256-color palette
    } else {
      XCTFail("Expected extended color")
    }
  }
  
  func testTextColorDoublePureRed() {
    let color = TextColor(rgb: (1.0, 0.0, 0.0), fullColorSupport: false)
    XCTAssertEqual(color, .red)
    XCTAssertFalse(color.isExtended)
  }
  
  func testTextColorDoublePureGreen() {
    let color = TextColor(rgb: (0.0, 1.0, 0.0), fullColorSupport: false)
    XCTAssertEqual(color, .lime)
    XCTAssertFalse(color.isExtended)
  }
  
  func testTextColorDoublePureBlue() {
    let color = TextColor(rgb: (0.0, 0.0, 1.0), fullColorSupport: false)
    XCTAssertEqual(color, .blue)
    XCTAssertFalse(color.isExtended)
  }
  
  func testTextColorDoubleHalfRed() {
    let color = TextColor(rgb: (0.5, 0.0, 0.0), fullColorSupport: false)
    XCTAssertEqual(color, .maroon)
    XCTAssertFalse(color.isExtended)
  }
  
  func testTextColorDoubleWhite() {
    let color = TextColor(rgb: (1.0, 1.0, 1.0), fullColorSupport: false)
    XCTAssertEqual(color, .white)
    XCTAssertFalse(color.isExtended)
  }
  
  func testTextColorDoubleBlack() {
    let color = TextColor(rgb: (0.0, 0.0, 0.0), fullColorSupport: false)
    XCTAssertEqual(color, .black)
    XCTAssertFalse(color.isExtended)
  }
  
  func testTextColorDoubleGray() {
    let color = TextColor(rgb: (0.75, 0.75, 0.75), fullColorSupport: false)
    XCTAssertEqual(color, .silver)
    XCTAssertFalse(color.isExtended)
  }
  
  func testTextColorDoubleExtendedMode() {
    let color = TextColor(rgb: (0.48, 0.18, 0.26), fullColorSupport: true)
    XCTAssertTrue(color.isExtended)
  }
  
  func testTextColorDoubleClampingAbove() {
    // Values above 1.0 should be clamped to 1.0
    let color = TextColor(rgb: (1.5, 1.5, 1.5), fullColorSupport: false)
    XCTAssertEqual(color, .white)
  }
  
  func testTextColorDoubleClampingBelow() {
    // Values below 0.0 should be clamped to 0.0
    let color = TextColor(rgb: (-0.1, -0.1, -0.1), fullColorSupport: false)
    XCTAssertEqual(color, .black)
  }
  
  func testBackgroundColorPureRed() {
    let color = BackgroundColor(color: (255, 0, 0), fullColorSupport: false)
    XCTAssertEqual(color, .lightRed)
    XCTAssertFalse(color.isExtended)
  }
  
  func testBackgroundColorPureGreen() {
    let color = BackgroundColor(color: (0, 255, 0), fullColorSupport: false)
    XCTAssertEqual(color, .lightGreen)
    XCTAssertFalse(color.isExtended)
  }
  
  func testBackgroundColorPureBlue() {
    let color = BackgroundColor(color: (0, 0, 255), fullColorSupport: false)
    XCTAssertEqual(color, .lightBlue)
    XCTAssertFalse(color.isExtended)
  }
  
  func testBackgroundColorPureYellow() {
    let color = BackgroundColor(color: (255, 255, 0), fullColorSupport: false)
    XCTAssertEqual(color, .lightYellow)
    XCTAssertFalse(color.isExtended)
  }
  
  func testBackgroundColorPureWhite() {
    let color = BackgroundColor(color: (255, 255, 255), fullColorSupport: false)
    XCTAssertEqual(color, .lightWhite)
    XCTAssertFalse(color.isExtended)
  }
  
  func testBackgroundColorPureBlack() {
    let color = BackgroundColor(color: (0, 0, 0), fullColorSupport: false)
    XCTAssertEqual(color, .black)
    XCTAssertFalse(color.isExtended)
  }
  
  func testBackgroundColorPureCyan() {
    let color = BackgroundColor(color: (0, 255, 255), fullColorSupport: false)
    XCTAssertEqual(color, .lightCyan)
    XCTAssertFalse(color.isExtended)
  }
  
  func testBackgroundColorPureMagenta() {
    let color = BackgroundColor(color: (255, 0, 255), fullColorSupport: false)
    XCTAssertEqual(color, .lightMagenta)
    XCTAssertFalse(color.isExtended)
  }
  
  func testBackgroundColorDarkRed() {
    let color = BackgroundColor(color: (128, 0, 0), fullColorSupport: false)
    XCTAssertEqual(color, .red)
    XCTAssertFalse(color.isExtended)
  }
  
  func testBackgroundColorDarkGreen() {
    let color = BackgroundColor(color: (0, 128, 0), fullColorSupport: false)
    XCTAssertEqual(color, .green)
    XCTAssertFalse(color.isExtended)
  }
  
  func testBackgroundColorDarkBlue() {
    let color = BackgroundColor(color: (0, 0, 128), fullColorSupport: false)
    XCTAssertEqual(color, .blue)
    XCTAssertFalse(color.isExtended)
  }
  
  func testBackgroundColorDarkYellow() {
    let color = BackgroundColor(color: (128, 128, 0), fullColorSupport: false)
    XCTAssertEqual(color, .yellow)
    XCTAssertFalse(color.isExtended)
  }
  
  func testBackgroundColorDarkCyan() {
    let color = BackgroundColor(color: (0, 128, 128), fullColorSupport: false)
    XCTAssertEqual(color, .cyan)
    XCTAssertFalse(color.isExtended)
  }
  
  func testBackgroundColorDarkMagenta() {
    let color = BackgroundColor(color: (128, 0, 128), fullColorSupport: false)
    XCTAssertEqual(color, .magenta)
    XCTAssertFalse(color.isExtended)
  }
  
  func testBackgroundColorGray() {
    let color = BackgroundColor(color: (192, 192, 192), fullColorSupport: false)
    XCTAssertEqual(color, .white)
    XCTAssertFalse(color.isExtended)
  }
  
  func testBackgroundColorDarkGray() {
    let color = BackgroundColor(color: (64, 64, 64), fullColorSupport: false)
    XCTAssertEqual(color, .black)
    XCTAssertFalse(color.isExtended)
  }
  
  func testBackgroundColorExtendedMode() {
    let color = BackgroundColor(color: (123, 45, 67), fullColorSupport: true)
    XCTAssertTrue(color.isExtended)
  }
  
  func testBackgroundColorExtendedModeExactBlack() {
    let color = BackgroundColor(color: (0, 0, 0), fullColorSupport: true)
    // In extended mode, should map to extended color code
    XCTAssertTrue(color.isExtended)
    if case .extended(let code) = color {
      XCTAssertEqual(code, 0) // Black in 256-color palette
    } else {
      XCTFail("Expected extended color")
    }
  }
  
  func testBackgroundColorDoublePureRed() {
    let color = BackgroundColor(rgb: (1.0, 0.0, 0.0), fullColorSupport: false)
    XCTAssertEqual(color, .lightRed)
    XCTAssertFalse(color.isExtended)
  }
  
  func testBackgroundColorDoublePureGreen() {
    let color = BackgroundColor(rgb: (0.0, 1.0, 0.0), fullColorSupport: false)
    XCTAssertEqual(color, .lightGreen)
    XCTAssertFalse(color.isExtended)
  }
  
  func testBackgroundColorDoublePureBlue() {
    let color = BackgroundColor(rgb: (0.0, 0.0, 1.0), fullColorSupport: false)
    XCTAssertEqual(color, .lightBlue)
    XCTAssertFalse(color.isExtended)
  }
  
  func testBackgroundColorDoubleHalfRed() {
    let color = BackgroundColor(rgb: (0.5, 0.0, 0.0), fullColorSupport: false)
    XCTAssertEqual(color, .red)
    XCTAssertFalse(color.isExtended)
  }
  
  func testBackgroundColorDoubleWhite() {
    let color = BackgroundColor(rgb: (1.0, 1.0, 1.0), fullColorSupport: false)
    XCTAssertEqual(color, .lightWhite)
    XCTAssertFalse(color.isExtended)
  }
  
  func testBackgroundColorDoubleBlack() {
    let color = BackgroundColor(rgb: (0.0, 0.0, 0.0), fullColorSupport: false)
    XCTAssertEqual(color, .black)
    XCTAssertFalse(color.isExtended)
  }
  
  func testBackgroundColorDoubleGray() {
    let color = BackgroundColor(rgb: (0.75, 0.75, 0.75), fullColorSupport: false)
    XCTAssertEqual(color, .white)
    XCTAssertFalse(color.isExtended)
  }
  
  func testBackgroundColorDoubleExtendedMode() {
    let color = BackgroundColor(rgb: (0.48, 0.18, 0.26), fullColorSupport: true)
    XCTAssertTrue(color.isExtended)
  }
  
  func testBackgroundColorDoubleClampingAbove() {
    // Values above 1.0 should be clamped to 1.0
    let color = BackgroundColor(rgb: (1.5, 1.5, 1.5), fullColorSupport: false)
    XCTAssertEqual(color, .lightWhite)
  }
  
  func testBackgroundColorDoubleClampingBelow() {
    // Values below 0.0 should be clamped to 0.0
    let color = BackgroundColor(rgb: (-0.1, -0.1, -0.1), fullColorSupport: false)
    XCTAssertEqual(color, .black)
  }
  
  func testTextColorApproximateOrange() {
    // Orange (255, 165, 0) should approximate to yellow or red
    let color = TextColor(color: (255, 165, 0), fullColorSupport: false)
    XCTAssertFalse(color.isExtended)
    // Should be one of the basic 16 colors
    XCTAssertTrue([.yellow, .red, .maroon].contains(color))
  }
  
  func testTextColorApproximatePink() {
    // Pink (255, 192, 203) should approximate to white or similar
    let color = TextColor(color: (255, 192, 203), fullColorSupport: false)
    XCTAssertFalse(color.isExtended)
    XCTAssertTrue([.white, .silver, .fuchsia].contains(color))
  }
  
  func testBackgroundColorApproximateOrange() {
    // Orange should approximate to yellow or red
    let color = BackgroundColor(color: (255, 165, 0), fullColorSupport: false)
    XCTAssertFalse(color.isExtended)
    XCTAssertTrue([.lightYellow, .lightRed, .yellow].contains(color))
  }
  
  func testBackgroundColorApproximatePink() {
    // Pink should approximate to white or magenta
    let color = BackgroundColor(color: (255, 192, 203), fullColorSupport: false)
    XCTAssertFalse(color.isExtended)
    XCTAssertTrue([.lightWhite, .white, .lightMagenta].contains(color))
  }
  
  func testTextColorExtendedCodeRange() {
    // Test that various RGB values in extended mode produce valid codes (0-255)
    let testColors: [(UInt8, UInt8, UInt8)] = [
      (0, 0, 0),
      (128, 128, 128),
      (255, 255, 255),
      (100, 50, 25),
      (200, 150, 100)
    ]
    
    for rgb in testColors {
      let color = TextColor(color: rgb, fullColorSupport: true)
      if case .extended(let code) = color {
        XCTAssertLessThanOrEqual(code, 255)
        XCTAssertGreaterThanOrEqual(code, 0)
      } else {
        XCTFail("Expected extended color for \(rgb)")
      }
    }
  }
  
  func testBackgroundColorExtendedCodeRange() {
    // Test that various RGB values in extended mode produce valid codes (0-255)
    let testColors: [(UInt8, UInt8, UInt8)] = [
      (0, 0, 0),
      (128, 128, 128),
      (255, 255, 255),
      (100, 50, 25),
      (200, 150, 100)
    ]
    
    for rgb in testColors {
      let color = BackgroundColor(color: rgb, fullColorSupport: true)
      if case .extended(let code) = color {
        XCTAssertLessThanOrEqual(code, 255)
        XCTAssertGreaterThanOrEqual(code, 0)
      } else {
        XCTFail("Expected extended color for \(rgb)")
      }
    }
  }
  
  func testTextColorPropertiesFromRGB() {
    let color = TextColor(color: (255, 0, 0), fullColorSupport: false)
    let properties = color.properties
    XCTAssertNotNil(properties)
  }
  
  func testBackgroundColorPropertiesFromRGB() {
    let color = BackgroundColor(color: (0, 255, 0), fullColorSupport: false)
    let properties = color.properties
    XCTAssertNotNil(properties)
  }
  
  func testTextColorCodePropertyBasicColors() {
    let red = TextColor(color: (255, 0, 0), fullColorSupport: false)
    XCTAssertEqual(red.code, 91) // Light red
    
    let green = TextColor(color: (0, 255, 0), fullColorSupport: false)
    XCTAssertEqual(green.code, 92) // Lime
    
    let blue = TextColor(color: (0, 0, 255), fullColorSupport: false)
    XCTAssertEqual(blue.code, 94) // Light blue
  }
  
  func testBackgroundColorCodePropertyBasicColors() {
    let red = BackgroundColor(color: (255, 0, 0), fullColorSupport: false)
    XCTAssertEqual(red.code, 101) // Light red
    
    let green = BackgroundColor(color: (0, 255, 0), fullColorSupport: false)
    XCTAssertEqual(green.code, 102) // Light green
    
    let blue = BackgroundColor(color: (0, 0, 255), fullColorSupport: false)
    XCTAssertEqual(blue.code, 104) // Light blue
  }
  
  func testTextColorExtendedCodeProperty() {
    let color = TextColor(color: (123, 45, 67), fullColorSupport: true)
    if case .extended(let expectedCode) = color {
      XCTAssertEqual(color.code, expectedCode)
    } else {
      XCTFail("Expected extended color")
    }
  }
  
  func testBackgroundColorExtendedCodeProperty() {
    let color = BackgroundColor(color: (123, 45, 67), fullColorSupport: true)
    if case .extended(let expectedCode) = color {
      XCTAssertEqual(color.code, expectedCode)
    } else {
      XCTFail("Expected extended color")
    }
  }
}
