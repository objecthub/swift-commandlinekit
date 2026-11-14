//
//  AnsiCodes.swift
//  CommandLineKit
//
//  Created by Matthias Zenger on 07/04/2018.
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

import Foundation

public struct AnsiCodes {
  
  public enum CursorStyle: UInt8, Sendable {
    case blockBlinking = 1
    case block = 2
    case lineBlinking = 3
    case line = 4
    case barBlinking = 5
    case bar = 6
  }
  
  public static let CSI: String = "\u{001B}["
  
  public static let eraseRight: String = escapeCode("0K")
  public static let homeCursor: String = escapeCode("H")
  
  /// The following line is a hack. It is the only reliable way I could get "Terminal.app" on
  /// macOS to return to the beginning of the line
  public static let beginningOfLine: String = cursorBackward(3000) + cursorBackward(999)
  public static let endOfLine: String = cursorForward(3000) + cursorForward(999)
  
  /// Clear screen
  public static let clearScreen: String = escapeCode("2J")
  public static let clearScreenCursorHome: String = AnsiCodes.clearScreen + AnsiCodes.homeCursor
  public static let clearCursorToBottom: String = escapeCode("0J")
  public static let clearTopToCursor: String = escapeCode("1J")
  
  /// Clear line
  public static let clearLine: String = escapeCode("2K")
  public static let clearCursorToEnd: String = escapeCode("0K")
  public static let clearBeginningToCursor: String = escapeCode("1K")
  
  /// Save/restore cursor position
  public static let savePos: String = escapeCode("s")
  public static let restorePos: String = escapeCode("u")
  
  public static let cursorLocation: String = escapeCode("6n")
  public static let origTermColor: String = escapeCode("0m")
  
  public static func escapeCode(_ input: String) -> String {
    return AnsiCodes.CSI + input
  }
  
  public static func setCursorStyle(_ style: CursorStyle) -> String {
    return escapeCode("\(style.rawValue) q")
  }
  
  public static func setCursorColumn(_ column: Int) -> String {
    return escapeCode("\(column)G")
  }
  
  public static func setCursorPos(_ row: Int, _ column: Int) -> String {
    return escapeCode("\(row);\(column)H")
  }
  
  public static func cursorUp(_ rows: Int = 1) -> String {
    guard rows > 0 else {
      return ""
    }
    return escapeCode("\(rows)A")
  }
  
  public static func cursorDown(_ rows: Int = 1) -> String {
    guard rows > 0 else {
      return ""
    }
    return escapeCode("\(rows)B")
  }
  
  public static func cursorForward(_ columns: Int = 1) -> String {
    guard columns > 0 else {
      return ""
    }
    return escapeCode("\(columns)C")
  }
  
  public static func cursorBackward(_ columns: Int = 1) -> String {
    guard columns > 0 else {
      return ""
    }
    return escapeCode("\(columns)D")
  }
  
  public static func nextLine(_ lines: Int = 1) -> String {
    return escapeCode("\(lines)E")
  }
  
  public static func previousLine(_ lines: Int = 1) -> String {
    return escapeCode("\(lines)F")
  }
  
  public static func moveLineDown(_ lines: Int = 1) -> String {
    return escapeCode("\(lines)E")
  }
  
  public static func moveLineUp(_ lines: Int = 1) -> String {
    return escapeCode("\(lines)F")
  }
  
  public static func insertLine(_ lines: Int = 1) -> String {
    return escapeCode("\(lines)L")
  }
  
  public static func deleteLine(_ lines: Int = 1) -> String {
    return escapeCode("\(lines)M")
  }
  
  public static func deleteChar(_ chars: Int = 1) -> String {
    return escapeCode("\(chars)P")
  }
  
  public static func termColor(color: Int, bold: Bool) -> String {
    return escapeCode("\(color);\(bold ? 1 : 0);49m")
  }
  
  public static func termColor256(color: Int) -> String {
    return escapeCode("38;5;\(color)m")
  }

  /// Returns `text` without ANSI escape sequences, i.e. only the text that is visible when
  /// `text` is written to a terminal. This removes CSI sequences (e.g. SGR codes for colors
  /// and text styles), string sequences such as OSC (e.g. hyperlinks and window titles),
  /// DCS, SOS, PM, and APC, as well as other two-character escape sequences.
  internal static func stripEscapeSequences(_ text: String) -> String {
    let scalars = text.unicodeScalars
    guard scalars.contains(where: { $0 == "\u{1B}" || $0 == "\u{9B}" || $0 == "\u{9D}" }) else {
      return text
    }
    var result = String.UnicodeScalarView()
    var i = scalars.startIndex
    // Skips a CSI sequence starting at `i` (after the introducer)
    func skipControlSequence() {
      while i < scalars.endIndex {
        let value = scalars[i].value
        i = scalars.index(after: i)
        if value >= 0x40 && value <= 0x7E {
          return
        } else if value < 0x20 || value > 0x3F {
          // Malformed sequence; stop skipping without consuming more characters
          return
        }
      }
    }
    // Skips a string sequence starting at `i` (after the introducer) up to and including
    // its terminator (BEL, ST, or ESC \)
    func skipStringSequence() {
      while i < scalars.endIndex {
        let scalar = scalars[i]
        i = scalars.index(after: i)
        if scalar == "\u{07}" || scalar == "\u{9C}" {
          return
        } else if scalar == "\u{1B}" {
          if i < scalars.endIndex && scalars[i] == "\\" {
            i = scalars.index(after: i)
          }
          return
        }
      }
    }
    while i < scalars.endIndex {
      let scalar = scalars[i]
      i = scalars.index(after: i)
      switch scalar {
        case "\u{9B}":
          skipControlSequence()
        case "\u{9D}":
          skipStringSequence()
        case "\u{1B}":
          guard i < scalars.endIndex else {
            break
          }
          let next = scalars[i]
          i = scalars.index(after: i)
          switch next {
            case "[":
              skipControlSequence()
            case "]", "P", "X", "^", "_":
              skipStringSequence()
            default:
              // Two-character escape sequence, possibly with intermediate bytes
              var value = next.value
              while value >= 0x20 && value <= 0x2F && i < scalars.endIndex {
                value = scalars[i].value
                i = scalars.index(after: i)
              }
          }
        default:
          result.append(scalar)
      }
    }
    return String(result)
  }
}
