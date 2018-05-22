//
//  AnsiCodesTests.swift
//  CommandLineKitTests
//
//  Created by Matthias Zenger on 08/04/2018.
//  Copyright © 2018 Google LLC
//  Copyright © 2017 Andy Best <andybest.net at gmail dot com>
//  Copyright © 2010-2014 Salvatore Sanfilippo <antirez at gmail dot com>
//  Copyright © 2010-2013 Pieter Noordhuis <pcnoordhuis at gmail dot com>
//
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  * Redistributions of source code must retain the above copyright notice,
//    this list of conditions and the following disclaimer.
//
//  * Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
//  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
//  ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

import XCTest
@testable import CommandLineKit

class AnsiCodesTests: XCTestCase {

  func testGenerateEscapeCode() {
    XCTAssertEqual(AnsiCodes.escapeCode("foo"), "\u{001B}[foo")
  }
  
  func testEraseRight() {
    XCTAssertEqual(AnsiCodes.eraseRight, "\u{001B}[0K")
  }
  
  func testCursorForward() {
    XCTAssertEqual(AnsiCodes.cursorForward(10), "\u{001B}[10C")
  }
  
  func testClearScreen() {
    XCTAssertEqual(AnsiCodes.clearScreen, "\u{001B}[2J")
  }
  
  func testHomeCursor() {
    XCTAssertEqual(AnsiCodes.homeCursor, "\u{001B}[H")
  }
}
