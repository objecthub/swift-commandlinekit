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
    if Terminal.isWideCharacter(value) {
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
}
