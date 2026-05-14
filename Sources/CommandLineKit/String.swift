//
//  String.swift
//  CommandLineKit
//
//  Created by Matthias Zenger on 14/05/2026.
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

extension String {

  /// Returns the width (in characters) when displayed on a terminal.
  public var terminalDisplayWidth: Int {
    self.unicodeScalars.reduce(0) { $0 + self.scalarDisplayWidth($1) }
  }
  
  private func scalarDisplayWidth(_ scalar: Unicode.Scalar) -> Int {
    let value = scalar.value
    // Null character
    if value == 0 {
      return 0
    }
    // Combining/non-spacing marks and other zero-width characters
    if value == 0x200B { // Zero-width space
      return 0
    }
    if value == 0xFEFF { // Zero-width no-break space / BOM
      return 0
    }
    // Variation selectors (emoji/text presentation modifiers, always zero-width)
    if (value >= 0xFE00 && value <= 0xFE0F) { // Variation Selectors 1–16
      return 0
    }
    if (value >= 0xE0100 && value <= 0xE01EF) { // Variation Selectors Supplement
      return 0
    }
    // Skip combining characters (they modify the previous character)
    let ch = Character(scalar)
    if ch.unicodeScalars.allSatisfy({ isCombining($0) }) {
      return 0
    }
    // Control characters
    if value < 32 || (value >= 0x7F && value < 0xA0) {
      return 0
    }
    // Check for wide character ranges (double-width)
    if isWideCharacter(value) {
      return 2
    }
    return 1
  }
  
  private func isCombining(_ scalar: Unicode.Scalar) -> Bool {
    let value = scalar.value
    return (
      // Combining Diacritical Marks
      (value >= 0x0300 && value <= 0x036F) ||
      // Combining Diacritical Marks Extended
      (value >= 0x1AB0 && value <= 0x1AFF) ||
      // Combining Diacritical Marks Supplement
      (value >= 0x1DC0 && value <= 0x1DFF) ||
      // Combining Diacritical Marks for Symbols
      (value >= 0x20D0 && value <= 0x20FF) ||
      // Variation selectors
      (value >= 0xFE20 && value <= 0xFE2F)
    )
  }
  
  private func isWideCharacter(_ value: UInt32) -> Bool {
    switch value {
      // CJK Unified Ideographs and common extensions
      case
        0x1100...0x115F,  // Hangul Jamo
        0x2600...0x26FF,  // Miscellaneous Symbols (☀︎, ❤︎, etc.)
        0x2700...0x27BF,  // Dingbats (✅, ✈, ✉, etc.)
        0x2E80...0x303E,  // CJK Radicals, Kangxi, etc.
        0x3041...0x33BF,  // Hiragana, Katakana, Bopomofo, Hangul Compat, Kanbun, etc.
        0x33FF...0x33FF,  // CJK Compatibility
        0x3400...0x4DBF,  // CJK Extension A
        0x4E00...0x9FFF,  // CJK Unified Ideographs
        0xA000...0xA4CF,  // Yi
        0xA960...0xA97F,  // Hangul Jamo Extended-A
        0xAC00...0xD7FF,  // Hangul Syllables and Jamo Extended-B
        0xF900...0xFAFF,  // CJK Compatibility Ideographs
        0xFE10...0xFE1F,  // Vertical Forms
        0xFE30...0xFE6F,  // CJK Compatibility Forms, Small Form Variants
        0xFF01...0xFF60,  // Fullwidth ASCII and punctuation
        0xFFE0...0xFFE6,  // Fullwidth signs
                          // Supplementary wide blocks
        0x1B000...0x1B12F, // Kana Supplement/Extended
        0x1F004...0x1F004, // Mahjong tile
        0x1F0CF...0x1F0CF, // Playing card
        0x1F200...0x1F251, // Enclosed CJK
        0x1F300...0x1F6FF, // Misc symbols, emoticons, transport
        0x1F900...0x1F9FF, // Supplemental symbols
        0x1FA00...0x1FA6F, // Chess symbols
        0x1FA70...0x1FAFF, // Symbols and pictographs extended-A
        0x20000...0x2A6DF, // CJK Extension B
        0x2A700...0x2CEAF, // CJK Extensions C, D, E
        0x2CEB0...0x2EBEF, // CJK Extension F
        0x2F800...0x2FA1F, // CJK Compatibility Supplement
        0x30000...0x3134F: // CJK Extension G
        return true
      default:
        return false
    }
  }
}
