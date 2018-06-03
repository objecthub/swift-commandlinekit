//
//  EditStateTests.swift
//  CommandLineKitTests
//
//  Created by Matthias Zenger on 08/04/2018.
//  Copyright © 2018 Google LLC
//  Copyright © 2017 Andy Best <andybest.net at gmail dot com>
//  Copyright © 2010-2014 Salvatore Sanfilippo <antirez at gmail dot com>
//  Copyright © 2010-2013 Pieter Noordhuis <pcnoordhuis at gmail dot com>
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
//  * Neither the name of the copyright holder nor the names of its contributors
//    may be used to endorse or promote products derived from this software without
//    specific prior written permission.
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

class EditStateTests: XCTestCase {

  func testInitEmptyBuffer() {
    let s = EditState(prompt: "$ ")
    XCTAssertEqual(s.buffer, "")
    XCTAssertEqual(s.location, s.buffer.startIndex)
    XCTAssertEqual(s.prompt, "$ ")
  }
  
  func testInsertCharacter() {
    let s = EditState(prompt: "")
    XCTAssert(s.insertCharacter("A"["A".startIndex]))
    XCTAssertEqual(s.buffer, "A")
    XCTAssertEqual(s.location, s.buffer.endIndex)
    XCTAssertEqual(s.cursorPosition, 1)
  }
  
  func testBackspace() {
    let s = EditState(prompt: "")
    XCTAssert(s.insertCharacter("A"["A".startIndex]))
    XCTAssertTrue(s.backspace())
    XCTAssertEqual(s.buffer, "")
    XCTAssertEqual(s.location, s.buffer.startIndex)
    // No more characters left, so backspace should return false
    XCTAssertFalse(s.backspace())
  }
  
  func testMoveLeft() {
    let s = EditState(prompt: "")
    s.buffer = "Hello"
    s.location = s.buffer.endIndex
    XCTAssertTrue(s.moveLeft())
    XCTAssertEqual(s.cursorPosition, 4)
    s.location = s.buffer.startIndex
    XCTAssertFalse(s.moveLeft())
  }

  func testMoveRight() {
    let s = EditState(prompt: "")
    s.buffer = "Hello"
    s.location = s.buffer.startIndex
    XCTAssertTrue(s.moveRight())
    XCTAssertEqual(s.cursorPosition, 1)
    s.location = s.buffer.endIndex
    XCTAssertFalse(s.moveRight())
  }
  
  func testMoveHome() {
    let s = EditState(prompt: "")
    s.buffer = "Hello"
    s.location = s.buffer.endIndex
    XCTAssertTrue(s.moveHome())
    XCTAssertEqual(s.cursorPosition, 0)
    XCTAssertFalse(s.moveHome())
  }
  
  func testMoveEnd() {
    let s = EditState(prompt: "")
    s.buffer = "Hello"
    s.location = s.buffer.startIndex
    XCTAssertTrue(s.moveEnd())
    XCTAssertEqual(s.cursorPosition, 5)
    XCTAssertFalse(s.moveEnd())
  }
  
  func testRemovePreviousWord() {
    let s = EditState(prompt: "")
    s.buffer = "Hello world"
    s.location = s.buffer.endIndex
    XCTAssertTrue(s.deletePreviousWord())
    XCTAssertEqual(s.buffer, "Hello ")
    XCTAssertEqual(s.location, "Hello ".endIndex)
    s.buffer = ""
    s.location = s.buffer.endIndex
    XCTAssertFalse(s.deletePreviousWord())
    // Test with cursor location in the middle of the text
    s.buffer = "This is a test"
    s.location = s.buffer.index(s.buffer.startIndex, offsetBy: 8)
    XCTAssertTrue(s.deletePreviousWord())
    XCTAssertEqual(s.buffer, "This a test")
  }
  
  func testDeleteToEndOfLine() {
    let s = EditState(prompt: "")
    s.buffer = "Hello world"
    s.location = s.buffer.endIndex
    XCTAssertFalse(s.deleteToEndOfLine())
    s.location = s.buffer.index(s.buffer.startIndex, offsetBy: 5)
    XCTAssertTrue(s.deleteToEndOfLine())
    XCTAssertEqual(s.buffer, "Hello")
  }
  
  func testDeleteCharacter() {
    let s = EditState(prompt: "")
    s.buffer = "Hello world"
    s.location = s.buffer.endIndex
    XCTAssertFalse(s.deleteCharacter())
    s.location = s.buffer.startIndex
    XCTAssertTrue(s.deleteCharacter())
    XCTAssertEqual(s.buffer, "ello world")
    s.location = s.buffer.index(s.buffer.startIndex, offsetBy: 5)
    XCTAssertTrue(s.deleteCharacter())
    XCTAssertEqual(s.buffer, "ello orld")
  }
  
  func testEraseCharacterRight() {
    let s = EditState(prompt: "")
    s.buffer = "Hello"
    s.location = s.buffer.endIndex
    XCTAssertFalse(s.eraseCharacterRight())
    s.location = s.buffer.startIndex
    XCTAssertTrue(s.eraseCharacterRight())
    XCTAssertEqual(s.buffer, "ello")
    // Test empty buffer
    s.buffer = ""
    s.location = s.buffer.startIndex
    XCTAssertFalse(s.eraseCharacterRight())
  }
  
  func testSwapCharacters() {
    let s = EditState(prompt: "")
    s.buffer = "Hello"
    s.location = s.buffer.endIndex
    // Cursor at the end of the text
    XCTAssertTrue(s.swapCharacterWithPrevious())
    XCTAssertEqual(s.buffer, "Helol")
    XCTAssertEqual(s.location, s.buffer.endIndex)
    // Cursor in the middle of the text
    s.location = s.buffer.index(before: s.buffer.endIndex)
    XCTAssertTrue(s.swapCharacterWithPrevious())
    XCTAssertEqual(s.buffer, "Hello")
    XCTAssertEqual(s.location, s.buffer.endIndex)
    // Cursor at the start of the text
    s.location = s.buffer.startIndex
    XCTAssertTrue(s.swapCharacterWithPrevious())
    XCTAssertEqual(s.buffer, "eHllo")
    XCTAssertEqual(s.location, s.buffer.index(s.buffer.startIndex, offsetBy: 2))
  }
  
  static let allTests = [
    ("testInitEmptyBuffer", testInitEmptyBuffer),
    ("testInsertCharacter", testInsertCharacter),
    ("testBackspace", testBackspace),
    ("testMoveLeft", testMoveLeft),
    ("testMoveRight", testMoveRight),
    ("testMoveHome", testMoveHome),
    ("testMoveEnd", testMoveEnd),
    ("testRemovePreviousWord", testRemovePreviousWord),
    ("testDeleteToEndOfLine", testDeleteToEndOfLine),
    ("testDeleteCharacter", testDeleteCharacter),
    ("testEraseCharacterRight", testEraseCharacterRight),
    ("testSwapCharacters", testSwapCharacters),
  ]
}
