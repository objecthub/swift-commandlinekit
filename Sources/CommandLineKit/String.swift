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

  /// Returns the number of columns this string occupies when displayed on a monospaced
  /// terminal. This is the sum of the `terminalDisplayWidth` of all characters (i.e. grapheme
  /// clusters) of the string. Control characters (including newlines and tabs) do not
  /// contribute to the width.
  public var terminalDisplayWidth: Int {
    var width = 0
    for ch in self {
      width += ch.terminalDisplayWidth
    }
    return width
  }
}

extension Character {

  /// Returns the number of columns this character (i.e. extended grapheme cluster) occupies
  /// when displayed on a monospaced terminal. The width is derived from the widths of the
  /// Unicode scalars of the grapheme cluster (see `Unicode.Scalar.terminalDisplayWidth`):
  ///
  ///   - If the first scalar is wide (e.g. an ideograph, a Hangul syllable or an emoji with
  ///     default emoji presentation), the character has width 2. This covers emoji ZWJ
  ///     sequences, emoji modifier sequences (skin tones), emoji tag sequences, and
  ///     conjoining Hangul jamo sequences.
  ///   - If the first scalar has width 1 and it is followed by the emoji presentation
  ///     selector U+FE0F, the character has width 2 (e.g. ❤️ or keycaps like 1️⃣).
  ///   - Otherwise, the width is the sum of the widths of all scalars. Combining marks and
  ///     format characters have width 0, so a base character with combining accents has
  ///     width 1, and a pair of regional indicators (a flag) has width 2.
  ///
  /// Control characters (C0 and C1 controls, including newlines and tabs) have width 0.
  public var terminalDisplayWidth: Int {
    if let ascii = self.asciiValue {
      return ascii >= 0x20 && ascii < 0x7F ? 1 : 0
    }
    var iterator = self.unicodeScalars.makeIterator()
    guard let base = iterator.next() else {
      return 0
    }
    let baseWidth = base.terminalDisplayWidth
    if baseWidth == 2 {
      return 2
    }
    var width = baseWidth
    while let scalar = iterator.next() {
      if scalar.value == 0xFE0F && baseWidth == 1 {
        return 2
      }
      width += scalar.terminalDisplayWidth
    }
    return width
  }
}

extension Unicode.Scalar {

  /// Returns the number of columns this Unicode scalar occupies when displayed on a
  /// monospaced terminal independent of its context: 0, 1, or 2. The width is derived
  /// from the Unicode Character Database (see `Unicode.Scalar.terminalWidthUnicodeVersion`
  /// for the version):
  ///
  ///   - Width 0: control characters (C0 and C1 controls, including newlines and tabs),
  ///     nonspacing and enclosing combining marks (general categories Mn and Me, e.g.
  ///     U+0301, Hebrew points, Arabic harakat, variation selectors), format characters
  ///     (general category Cf, e.g. U+200B, ZWNJ, ZWJ, direction marks and isolates,
  ///     U+FEFF), line and paragraph separators, Hangul Jungseong and Jongseong, and
  ///     unassigned default ignorable code points. U+00AD SOFT HYPHEN and the prepended
  ///     concatenation marks (e.g. U+0600) are visible and have width 1.
  ///   - Width 2: characters with East Asian Width W (wide) or F (fullwidth), which includes
  ///     all characters with default emoji presentation (e.g. U+231A, U+2614, U+1F600),
  ///     as well as unassigned code points in blocks reserved for wide characters (e.g.
  ///     CJK blocks, planes 2 and 3, and emoji blocks).
  ///   - Width 1: all other scalars, including characters with East Asian Width A
  ///     (ambiguous) and emoji with default text presentation (e.g. U+2600, U+2764).
  public var terminalDisplayWidth: Int {
    let value = self.value
    if value >= 0x20 && value < 0x7F {
      return 1
    } else if TerminalWidthTables.contains(value, in: TerminalWidthTables.zeroWidth) {
      return 0
    } else if TerminalWidthTables.contains(value, in: TerminalWidthTables.wide) {
      return 2
    } else {
      return 1
    }
  }

  /// The version of the Unicode Character Database from which `terminalDisplayWidth`
  /// is derived.
  public static var terminalWidthUnicodeVersion: String {
    return TerminalWidthTables.unicodeVersion
  }
}

extension TerminalWidthTables {

  /// Returns true if `value` is contained in one of the ranges of `table`. `table` is a
  /// sorted array of non-overlapping ranges, each represented by its first and last value.
  static func contains(_ value: UInt32, in table: [UInt32]) -> Bool {
    guard table.count >= 2, value >= table[0], value <= table[table.count - 1] else {
      return false
    }
    var lo = 0
    var hi = table.count / 2 - 1
    while lo <= hi {
      let mid = (lo + hi) / 2
      if value < table[2 * mid] {
        hi = mid - 1
      } else if value > table[2 * mid + 1] {
        lo = mid + 1
      } else {
        return true
      }
    }
    return false
  }
}
