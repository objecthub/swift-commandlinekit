//
//  TerminalWidthTests.swift
//  CommandLineKitTests
//
//  Created by Matthias Zenger on 14/11/2026.
//  Copyright © 2026 Matthias Zenger. All rights reserved.
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

class TerminalWidthTests: XCTestCase {

  private func width(_ value: UInt32) -> Int {
    return Unicode.Scalar(value)!.terminalDisplayWidth
  }

  private func assertWidth(_ ranges: [ClosedRange<UInt32>],
                           _ expected: Int,
                           file: StaticString = #filePath,
                           line: UInt = #line) {
    for range in ranges {
      for value in range {
        let scalar = Unicode.Scalar(value)!
        XCTAssertEqual(scalar.terminalDisplayWidth, expected,
                       "U+\(String(value, radix: 16, uppercase: true))",
                       file: file, line: line)
        XCTAssertEqual(String(Character(scalar)).terminalDisplayWidth, expected,
                       "U+\(String(value, radix: 16, uppercase: true))",
                       file: file, line: line)
      }
    }
  }

  func testUnicodeVersion() {
    XCTAssertFalse(Unicode.Scalar.terminalWidthUnicodeVersion.isEmpty)
  }

  func testTablesAreSortedAndDisjoint() {
    for table in [TerminalWidthTables.zeroWidth, TerminalWidthTables.wide] {
      XCTAssertEqual(table.count % 2, 0)
      var previous: UInt32? = nil
      for i in stride(from: 0, to: table.count, by: 2) {
        XCTAssertLessThanOrEqual(table[i], table[i + 1])
        if let previous = previous {
          XCTAssertLessThan(previous, table[i])
        }
        previous = table[i + 1]
      }
    }
    for i in stride(from: 0, to: TerminalWidthTables.zeroWidth.count, by: 2) {
      for value in TerminalWidthTables.zeroWidth[i]...TerminalWidthTables.zeroWidth[i + 1] {
        XCTAssertFalse(TerminalWidthTables.contains(value, in: TerminalWidthTables.wide))
      }
    }
  }

  func testASCII() {
    assertWidth([0x20...0x7E], 1)
    XCTAssertEqual("Hello, World!".terminalDisplayWidth, 13)
  }

  func testControlCharacters() {
    // Control characters have width 0
    assertWidth([0x00...0x1F, 0x7F...0x9F], 0)
    XCTAssertEqual("a\tb\nc\r\nd\u{1B}".terminalDisplayWidth, 4)
    XCTAssertEqual(Character("\r\n").terminalDisplayWidth, 0)
  }

  func testEmojiPresentationIsWide() {
    // East Asian Width W, default emoji presentation
    assertWidth([0x231A...0x231B, 0x2329...0x232A, 0x23E9...0x23EC, 0x23F0...0x23F0,
                 0x23F3...0x23F3, 0x25FD...0x25FE, 0x2B1B...0x2B1C, 0x2B50...0x2B50,
                 0x2B55...0x2B55], 2)
    XCTAssertEqual("⌚⏰⭐⭕".terminalDisplayWidth, 8)
  }

  func testWideSymbols() {
    // CJK compatibility (square units) and Yijing hexagram symbols
    assertWidth([0x33C0...0x33FE, 0x4DC0...0x4DFF], 2)
    XCTAssertEqual("㏀䷀".terminalDisplayWidth, 4)
  }

  func testMiscellaneousSymbolsAndDingbats() {
    // Only the characters with East Asian Width W are wide in the Miscellaneous Symbols
    // and Dingbats blocks; all others have text presentation by default and are narrow
    let wide: [ClosedRange<UInt32>] = [
      0x2614...0x2615, 0x2630...0x2637, 0x2648...0x2653, 0x267F...0x267F, 0x268A...0x268F,
      0x2693...0x2693, 0x26A1...0x26A1, 0x26AA...0x26AB, 0x26BD...0x26BE, 0x26C4...0x26C5,
      0x26CE...0x26CE, 0x26D4...0x26D4, 0x26EA...0x26EA, 0x26F2...0x26F3, 0x26F5...0x26F5,
      0x26FA...0x26FA, 0x26FD...0x26FD, 0x2705...0x2705, 0x270A...0x270B, 0x2728...0x2728,
      0x274C...0x274C, 0x274E...0x274E, 0x2753...0x2755, 0x2757...0x2757, 0x2795...0x2797,
      0x27B0...0x27B0, 0x27BF...0x27BF
    ]
    for value in UInt32(0x2600)...0x27BF {
      let expected = wide.contains { $0.contains(value) } ? 2 : 1
      XCTAssertEqual(width(value), expected, "U+\(String(value, radix: 16, uppercase: true))")
    }
    XCTAssertEqual("☀".terminalDisplayWidth, 1)
    XCTAssertEqual("✂".terminalDisplayWidth, 1)
    XCTAssertEqual("❤".terminalDisplayWidth, 1)
    XCTAssertEqual("✓".terminalDisplayWidth, 1)
    XCTAssertEqual("☔".terminalDisplayWidth, 2)
    XCTAssertEqual("✅".terminalDisplayWidth, 2)
  }

  func testZeroWidthFormatCharacters() {
    // ZWSP, ZWNJ, ZWJ, direction marks, embeddings and overrides, word joiner,
    // invisible operators, isolates, and BOM
    assertWidth([0x200B...0x200F, 0x202A...0x202E, 0x2060...0x206F, 0xFEFF...0xFEFF], 0)
    XCTAssertEqual("a\u{200C}b\u{200D}c\u{200E}d\u{2066}e\u{2069}".terminalDisplayWidth, 5)
  }

  func testZeroWidthCombiningMarks() {
    // Combining diacritical marks, Cyrillic, Hebrew, and Arabic marks
    assertWidth([0x0300...0x036F, 0x0483...0x0489], 0)
    assertWidth([0x0591...0x05BD, 0x05BF...0x05BF, 0x05C1...0x05C2, 0x05C4...0x05C5,
                 0x05C7...0x05C7], 0)
    assertWidth([0x0610...0x061A, 0x064B...0x065F, 0x0670...0x0670], 0)
    // Hebrew punctuation in the same block is visible
    assertWidth([0x05BE...0x05BE, 0x05C0...0x05C0, 0x05C3...0x05C3, 0x05C6...0x05C6], 1)
    // Variation selectors
    assertWidth([0xFE00...0xFE0F, 0xE0100...0xE01EF], 0)
    XCTAssertEqual("שָׁלוֹם".terminalDisplayWidth, 4)
    XCTAssertEqual("مَرْحَبًا".terminalDisplayWidth, 5)
    XCTAssertEqual("e\u{301}".terminalDisplayWidth, 1)
    XCTAssertEqual("\u{301}".terminalDisplayWidth, 0)
    XCTAssertEqual("a\u{301}\u{302}\u{303}".terminalDisplayWidth, 1)
  }

  func testVisibleFormatCharacters() {
    // Soft hyphen and prepended concatenation marks are visible
    XCTAssertEqual(width(0x00AD), 1)
    XCTAssertEqual(width(0x0600), 1)
    XCTAssertEqual(width(0x06DD), 1)
  }

  func testAmbiguousWidthIsNarrow() {
    XCTAssertEqual("±αЖ─①".terminalDisplayWidth, 5)
  }

  func testSupplementaryPlanes() {
    XCTAssertEqual("😀".terminalDisplayWidth, 2)
    XCTAssertEqual("🦀".terminalDisplayWidth, 2)
    XCTAssertEqual("𝐀𝐁".terminalDisplayWidth, 2) // Mathematical bold letters
    XCTAssertEqual("𠀀".terminalDisplayWidth, 2)  // CJK Extension B
    XCTAssertEqual(width(0x1F600), 2)
    XCTAssertEqual(width(0x1D400), 1)
    XCTAssertEqual(width(0x20000), 2)
    XCTAssertEqual(width(0x2FFFD), 2)          // Unassigned, reserved for ideographs
    XCTAssertEqual(width(0x3FFFD), 2)
    XCTAssertEqual(width(0xE0001), 0)          // Language tag
    XCTAssertEqual(width(0x10FFFD), 1)         // Private use
  }

  func testHangul() {
    XCTAssertEqual("한국어".terminalDisplayWidth, 6)
    // Conjoining jamo: Choseong + Jungseong + Jongseong
    let decomposed = "\u{1112}\u{1161}\u{11AB}"
    XCTAssertEqual(decomposed.count, 1)
    XCTAssertEqual(decomposed.terminalDisplayWidth, 2)
    assertWidth([0x1160...0x11FF, 0xD7B0...0xD7C6], 0)
    XCTAssertEqual("ﾊﾝｸﾞﾙ".terminalDisplayWidth, 5) // Halfwidth forms
  }

  func testEmojiSequences() {
    XCTAssertEqual("❤️".terminalDisplayWidth, 2)          // Emoji presentation selector
    XCTAssertEqual("☀️".terminalDisplayWidth, 2)
    XCTAssertEqual("☀︎".terminalDisplayWidth, 1)          // Text presentation selector
    XCTAssertEqual("1️⃣".terminalDisplayWidth, 2)          // Keycap sequence
    XCTAssertEqual("👍🏽".terminalDisplayWidth, 2)          // Emoji modifier sequence
    XCTAssertEqual("🏽".terminalDisplayWidth, 2)           // Isolated emoji modifier
    XCTAssertEqual("👨‍👩‍👧‍👦".terminalDisplayWidth, 2)  // ZWJ sequence
    XCTAssertEqual("🏳️‍🌈".terminalDisplayWidth, 2)
    XCTAssertEqual("❤️‍🔥".terminalDisplayWidth, 2)
    XCTAssertEqual("🧑🏻‍💻".terminalDisplayWidth, 2)
    XCTAssertEqual("🇩🇪🇯🇵".terminalDisplayWidth, 4)      // Flags
    XCTAssertEqual("🏴󠁧󠁢󠁳󠁣󠁴󠁿".terminalDisplayWidth, 2)   // Tag sequence
    XCTAssertEqual("Hi 👋🏼!".terminalDisplayWidth, 6)
  }

  func testCharacterWidth() {
    XCTAssertEqual(Character("a").terminalDisplayWidth, 1)
    XCTAssertEqual(Character("世").terminalDisplayWidth, 2)
    XCTAssertEqual(Character("\u{200D}").terminalDisplayWidth, 0)
    XCTAssertEqual(Character("👨‍👩‍👧‍👦").terminalDisplayWidth, 2)
  }

  func testConsistency() {
    let text = "a☀✂⌚㏀\u{200D}\u{5B0}😀世界"
    // 1 + 1 + 1 + 2 + 2 + 0 + 0 + 2 + 2 + 2
    XCTAssertEqual(text.terminalDisplayWidth, 13)
    XCTAssertEqual(AnsiText.plain(text).terminalDisplayWidth, 13)
    XCTAssertEqual(AnsiText.plain(text).normalized.terminalDisplayWidth, 13)
    XCTAssertEqual(AnsiText.annotated(TextProperties(.red), "a☀✂", "⌚㏀").terminalDisplayWidth, 7)
    for value in UInt32(0)...0x3FFFF {
      if let scalar = Unicode.Scalar(value) {
        XCTAssertEqual(Terminal.isWideCharacter(value), scalar.terminalDisplayWidth == 2)
      }
    }
  }

  // Simulates how `Terminal.readLineSecure` groups entered scalars into characters, each of
  // which is displayed as one replacement character.
  private func secureInputCharacters(_ input: String) -> [String] {
    var characters: [String] = []
    for scalar in input.unicodeScalars {
      if let last = characters.last, Terminal.extendsCharacter(last, with: scalar) {
        characters[characters.count - 1].unicodeScalars.append(scalar)
      } else {
        characters.append(String(scalar))
      }
    }
    return characters
  }
  
  func testSecureInputCharacters() {
    XCTAssertEqual(secureInputCharacters("abc"), ["a", "b", "c"])
    XCTAssertEqual(secureInputCharacters("😀日a"), ["😀", "日", "a"])
    XCTAssertEqual(secureInputCharacters("e\u{0301}x"), ["e\u{0301}", "x"])
    XCTAssertEqual(secureInputCharacters("❤\u{FE0F}!"), ["❤\u{FE0F}", "!"])
    XCTAssertEqual(secureInputCharacters("👍🏽👍"), ["👍🏽", "👍"])
    XCTAssertEqual(secureInputCharacters("👨\u{200D}👩\u{200D}👧x"), ["👨\u{200D}👩\u{200D}👧", "x"])
    XCTAssertEqual(secureInputCharacters("🇩🇪🇫🇷"), ["🇩🇪", "🇫🇷"])
    XCTAssertEqual(secureInputCharacters("\u{1100}\u{1161}\u{11A8}"), ["\u{1100}\u{1161}\u{11A8}"])
    for input in ["abc", "😀日a", "e\u{0301}x", "❤\u{FE0F}!", "👍🏽👍", "👨\u{200D}👩\u{200D}👧x", "🇩🇪🇫🇷"] {
      XCTAssertEqual(secureInputCharacters(input).count, input.count)
      XCTAssertEqual(secureInputCharacters(input).joined(), input)
    }
  }

  static let allTests = [
    ("testUnicodeVersion", testUnicodeVersion),
    ("testTablesAreSortedAndDisjoint", testTablesAreSortedAndDisjoint),
    ("testASCII", testASCII),
    ("testControlCharacters", testControlCharacters),
    ("testEmojiPresentationIsWide", testEmojiPresentationIsWide),
    ("testWideSymbols", testWideSymbols),
    ("testMiscellaneousSymbolsAndDingbats", testMiscellaneousSymbolsAndDingbats),
    ("testZeroWidthFormatCharacters", testZeroWidthFormatCharacters),
    ("testZeroWidthCombiningMarks", testZeroWidthCombiningMarks),
    ("testVisibleFormatCharacters", testVisibleFormatCharacters),
    ("testAmbiguousWidthIsNarrow", testAmbiguousWidthIsNarrow),
    ("testSupplementaryPlanes", testSupplementaryPlanes),
    ("testHangul", testHangul),
    ("testEmojiSequences", testEmojiSequences),
    ("testCharacterWidth", testCharacterWidth),
    ("testConsistency", testConsistency),
    ("testSecureInputCharacters", testSecureInputCharacters),
  ]
}
