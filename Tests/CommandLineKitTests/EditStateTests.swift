//
//  EditStateTests.swift
//  CommandLineKitTests
//
//  Created by Matthias Zenger on 08/04/2018.
//  Copyright © 2018-2019 Google LLC
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
  
  func testCursorWidthAscii() {
    let s = EditState(prompt: "> ")
    XCTAssertEqual(s.promptWidth, 2)
    XCTAssertEqual(s.cursorWidth, 2)
    s.buffer = "Hello"
    s.location = s.buffer.endIndex
    XCTAssertEqual(s.cursorWidth, 7)
    XCTAssertEqual(s.lineWidth, 7)
    s.location = s.buffer.index(s.buffer.startIndex, offsetBy: 2)
    XCTAssertEqual(s.cursorWidth, 4)
    XCTAssertEqual(s.lineWidth, 7)
  }
  
  func testCursorWidthWideCharacters() {
    let s = EditState(prompt: "> ")
    s.buffer = "日本語ab"
    s.location = s.buffer.endIndex
    XCTAssertEqual(s.cursorPosition, 5)
    XCTAssertEqual(s.cursorWidth, 10)
    XCTAssertEqual(s.lineWidth, 10)
    s.location = s.buffer.index(s.buffer.startIndex, offsetBy: 2)
    XCTAssertEqual(s.cursorPosition, 2)
    XCTAssertEqual(s.cursorWidth, 6)
    XCTAssertTrue(s.moveLeft())
    XCTAssertEqual(s.cursorWidth, 4)
  }
  
  func testCursorWidthZeroWidthCharacters() {
    let s = EditState(prompt: "")
    // "e" followed by a combining acute accent, "x" followed by a zero-width space
    s.buffer = "ae\u{0301}x\u{200B}y"
    s.location = s.buffer.endIndex
    XCTAssertEqual(s.cursorWidth, 4)
    s.location = s.buffer.startIndex
    XCTAssertTrue(s.moveRight())
    XCTAssertTrue(s.moveRight())
    XCTAssertEqual(s.cursorWidth, 2)
  }
  
  func testPromptWidthIgnoresEscapeSequences() {
    let styled = TextProperties(.red, nil, .bold).apply(to: "λ> ")
    XCTAssertNotEqual(styled.count, 3)
    let s = EditState(prompt: styled)
    XCTAssertEqual(s.visiblePrompt, "λ> ")
    XCTAssertEqual(s.promptWidth, 3)
    s.buffer = "ab"
    s.location = s.buffer.endIndex
    XCTAssertEqual(s.cursorWidth, 5)
    let wide = EditState(prompt: "\u{1B}[1;32m入力\u{1B}[0m: ")
    XCTAssertEqual(wide.promptWidth, 6)
  }
  
  func testStripEscapeSequences() {
    XCTAssertEqual(AnsiCodes.stripEscapeSequences("plain"), "plain")
    XCTAssertEqual(AnsiCodes.stripEscapeSequences("\u{1B}[31;1mred\u{1B}[0m"), "red")
    XCTAssertEqual(AnsiCodes.stripEscapeSequences("a\u{1B}[38;5;208mb\u{1B}[mc"), "abc")
    // OSC hyperlink terminated by ST and by BEL
    XCTAssertEqual(
      AnsiCodes.stripEscapeSequences("\u{1B}]8;;http://x\u{1B}\\link\u{1B}]8;;\u{1B}\\!"), "link!")
    XCTAssertEqual(AnsiCodes.stripEscapeSequences("\u{1B}]0;title\u{07}> "), "> ")
    // Two-character escape sequences and character set designation
    XCTAssertEqual(AnsiCodes.stripEscapeSequences("\u{1B}7x\u{1B}8\u{1B}(By"), "xy")
    // C1 control sequence introducer
    XCTAssertEqual(AnsiCodes.stripEscapeSequences("\u{9B}1mz"), "z")
    // Trailing incomplete sequences
    XCTAssertEqual(AnsiCodes.stripEscapeSequences("q\u{1B}"), "q")
    XCTAssertEqual(AnsiCodes.stripEscapeSequences("q\u{1B}[12"), "q")
  }
  
  func testCursorRowAndColumn() {
    let s = EditState(prompt: "> ")
    s.buffer = "abcdefgh"
    s.location = s.buffer.endIndex
    XCTAssertEqual(s.cursorRowAndColumn(columns: 80).row, 0)
    XCTAssertEqual(s.cursorRowAndColumn(columns: 80).column, 10)
    XCTAssertEqual(s.cursorRowAndColumn(columns: 10).row, 1)
    XCTAssertEqual(s.cursorRowAndColumn(columns: 10).column, 0)
    XCTAssertEqual(s.cursorRowAndColumn(columns: 4).row, 2)
    XCTAssertEqual(s.cursorRowAndColumn(columns: 4).column, 2)
  }
  
  func testCursorRowAndColumnWrapsWideCharacters() {
    let s = EditState(prompt: "> ")
    // The third wide character does not fit into the last column of the first row,
    // so the terminal wraps it to the next row
    s.buffer = "ab日本語"
    s.location = s.buffer.endIndex
    XCTAssertEqual(s.cursorWidth, 10)
    let pos = s.cursorRowAndColumn(columns: 9)
    XCTAssertEqual(pos.row, 1)
    XCTAssertEqual(pos.column, 2)
    s.location = s.buffer.index(before: s.buffer.endIndex)
    let pos2 = s.cursorRowAndColumn(columns: 9)
    XCTAssertEqual(pos2.row, 0)
    XCTAssertEqual(pos2.column, 8)
    // Wide characters in the prompt
    let t = EditState(prompt: "入力: ")
    t.buffer = "x"
    t.location = t.buffer.endIndex
    let pos3 = t.cursorRowAndColumn(columns: 3)
    XCTAssertEqual(pos3.row, 2)
    XCTAssertEqual(pos3.column, 2)
  }
  
  func testInsertBeforeMultiByteCharacter() {
    // Regression test: the cursor index was reused after mutating the buffer, which put
    // the cursor into the middle of "👍" and crashed when computing the cursor position
    let s = EditState(prompt: "> ")
    XCTAssertTrue(s.insertCharacter("👍"))
    XCTAssertTrue(s.moveToWordStart())
    XCTAssertTrue(s.insertCharacter(")"))
    XCTAssertEqual(s.buffer, ")👍")
    XCTAssertEqual(s.cursorPosition, 1)
    XCTAssertEqual(s.cursorWidth, 3)
    XCTAssertEqual(s.cursorRowAndColumn(columns: 80).column, 3)
    XCTAssertTrue(s.insertCharacter("日"))
    XCTAssertEqual(s.buffer, ")日👍")
    XCTAssertEqual(s.cursorPosition, 2)
    XCTAssertEqual(s.cursorWidth, 5)
  }
  
  func testInsertCombiningCharacters() {
    let s = EditState(prompt: "")
    s.buffer = "ex"
    s.location = s.buffer.index(after: s.buffer.startIndex)
    XCTAssertTrue(s.insertCharacter("\u{301}"))
    XCTAssertEqual(s.buffer, "e\u{301}x")
    XCTAssertEqual(s.cursorPosition, 1)
    XCTAssertEqual(s.cursorWidth, 1)
    s.location = s.buffer.endIndex
    XCTAssertTrue(s.insertCharacter("👨"))
    XCTAssertTrue(s.insertCharacter("\u{200D}"))
    XCTAssertTrue(s.insertCharacter("👩"))
    XCTAssertEqual(s.buffer.count, 3)
    XCTAssertEqual(s.cursorPosition, 3)
    XCTAssertTrue(s.cursorAtEnd)
  }
  
  func testEditMultiByteCharacters() {
    let s = EditState(prompt: "")
    s.buffer = "a日😀b"
    s.location = s.buffer.index(s.buffer.startIndex, offsetBy: 2)
    XCTAssertTrue(s.backspace())
    XCTAssertEqual(s.buffer, "a😀b")
    XCTAssertEqual(s.cursorPosition, 1)
    XCTAssertTrue(s.deleteCharacter())
    XCTAssertEqual(s.buffer, "ab")
    XCTAssertEqual(s.cursorPosition, 1)
    s.buffer = "日本語"
    s.location = s.buffer.index(after: s.buffer.startIndex)
    XCTAssertTrue(s.eraseCharacterRight())
    XCTAssertEqual(s.buffer, "日語")
    XCTAssertEqual(s.cursorPosition, 1)
    XCTAssertTrue(s.swapCharacterWithPrevious())
    XCTAssertEqual(s.buffer, "語日")
    XCTAssertEqual(s.cursorPosition, 2)
    XCTAssertTrue(s.cursorAtEnd)
    s.buffer = "😀 日本 語"
    s.location = s.buffer.index(s.buffer.startIndex, offsetBy: 4)
    XCTAssertTrue(s.deletePreviousWord())
    XCTAssertEqual(s.buffer, "😀  語")
    XCTAssertEqual(s.cursorPosition, 2)
    XCTAssertEqual(s.cursorWidth, 3)
    XCTAssertTrue(s.deleteToEndOfLine())
    XCTAssertEqual(s.buffer, "😀 ")
    XCTAssertTrue(s.cursorAtEnd)
  }
  
  func testSetBufferMovesCursorToEnd() {
    let s = EditState(prompt: "")
    s.buffer = "日本語 and more"
    s.location = s.buffer.index(s.buffer.startIndex, offsetBy: 2)
    XCTAssertTrue(s.setBuffer("😀"))
    XCTAssertTrue(s.cursorAtEnd)
    XCTAssertEqual(s.cursorWidth, 2)
    XCTAssertTrue(s.insertCharacter("x"))
    XCTAssertEqual(s.buffer, "😀x")
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
    ("testCursorWidthAscii", testCursorWidthAscii),
    ("testCursorWidthWideCharacters", testCursorWidthWideCharacters),
    ("testCursorWidthZeroWidthCharacters", testCursorWidthZeroWidthCharacters),
    ("testPromptWidthIgnoresEscapeSequences", testPromptWidthIgnoresEscapeSequences),
    ("testStripEscapeSequences", testStripEscapeSequences),
    ("testCursorRowAndColumn", testCursorRowAndColumn),
    ("testCursorRowAndColumnWrapsWideCharacters", testCursorRowAndColumnWrapsWideCharacters),
    ("testInsertBeforeMultiByteCharacter", testInsertBeforeMultiByteCharacter),
    ("testInsertCombiningCharacters", testInsertCombiningCharacters),
    ("testEditMultiByteCharacters", testEditMultiByteCharacters),
    ("testSetBufferMovesCursorToEnd", testSetBufferMovesCursorToEnd),
  ]
}
