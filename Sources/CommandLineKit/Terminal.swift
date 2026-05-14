//
//  Terminal.swift
//  CommandLineKit
//
//  Created by Matthias Zenger on 19/04/2018.
//  Copyright © 2018-2026 Google LLC
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

public struct Terminal {
  
  /// Read a line securely in an ANSI terminal, i.e. without displaying what was
  /// entered. This will conceal all input with `replacementChar`. This method works
  /// also for unicode characters.
  public static func readLineSecure(prompt: AnsiText = "",
                                    maxLength: Int? = nil,
                                    allowEmpty: Bool = true,
                                    replacementChar: Character = "•") throws -> String {
    return try Terminal.readLineSecure(prompt: prompt.encodedString,
                                       maxLength: maxLength,
                                       allowEmpty: allowEmpty,
                                       replacementChar: replacementChar)
  }
  
  /// Read a line securely in an ANSI terminal, i.e. without displaying what was
  /// entered. This will conceal all input with `replacementChar`. This method works
  /// also for unicode characters.
  public static func readLineSecure(prompt: String = "",
                                    maxLength: Int? = nil,
                                    allowEmpty: Bool = true,
                                    replacementChar: Character = "•") throws -> String {
    print(prompt, terminator: "")
    fflush(stdout)
    var originalTermios = termios()
    tcgetattr(STDIN_FILENO, &originalTermios)
    var rawTermios = originalTermios
    rawTermios.c_lflag &= ~tcflag_t(ECHO | ICANON | ISIG)
    rawTermios.c_cc.16 = 1  // VMIN
    rawTermios.c_cc.17 = 0  // VTIME
    tcsetattr(STDIN_FILENO, TCSANOW, &rawTermios)
    defer {
      tcsetattr(STDIN_FILENO, TCSANOW, &originalTermios)
      print()
    }
    
    // Returns how many bytes a UTF-8 sequence has from its leading byte.
    func utf8SequenceLength(_ byte: UInt8) -> Int {
      switch byte {
        case 0x00...0x7F: return 1   // 0xxxxxxx  ASCII
        case 0xC0...0xDF: return 2   // 110xxxxx
        case 0xE0...0xEF: return 3   // 1110xxxx
        case 0xF0...0xF7: return 4   // 11110xxx
        default:          return 0   // Continuation byte or invalid
      }
    }
    
    // Reads one complete UTF-8 scalar from stdin. Returns nil on EOF/error.
    func readUnicodeScalar() -> (scalar: Unicode.Scalar, bytes: [UInt8])? {
      var firstByte: UInt8 = 0
      guard read(STDIN_FILENO, &firstByte, 1) == 1 else {
        return nil
      }
      let length = utf8SequenceLength(firstByte)
      guard length > 0 else { // skip invalid leading bytes
        return nil
      }
      var bytes: [UInt8] = [firstByte]
      // Read remaining continuation bytes
      for _ in 1..<length {
        var contByte: UInt8 = 0
        guard read(STDIN_FILENO, &contByte, 1) == 1 else { return nil }
          // Continuation bytes must be 10xxxxxx
        guard (contByte & 0xC0) == 0x80 else { return nil }
        bytes.append(contByte)
      }
      // Decode to a Unicode scalar
      guard let str = String(bytes: bytes, encoding: .utf8),
            let scalar = str.unicodeScalars.first else {
        return nil
      }
      return (scalar, bytes)
    }
    
    // Number of terminal columns a scalar occupies (0, 1, or 2).
    func terminalWidth(of scalar: Unicode.Scalar) -> Int {
      let v = scalar.value
      // Zero-width: combining marks, variation selectors, zero-width spaces, etc.
      if v == 0 {
        return 0
      }
      if v < 32 || (v >= 0x7F && v < 0xA0) { // C0/C1 control chars
        return 0                             // Full-width / wide characters (East Asian wide)
      }
      if Terminal.isWideCharacter(v) {
        return 2
      } else {
        return 1
      }
    }
    
    // Reads after ESC. Returns a tag indicating what was found.
    enum EscapeResult {
      case arrowLeft
      case arrowRight
      case arrowUp
      case arrowDown
      case unknown
    }
    
    // Reads an ANSI escape sequence after ESC has already been consumed.
    // Returns the final byte (e.g. 'A'/'B'/'C'/'D' for arrow keys), or nil for unknown.
    func readEscapeSequence() -> EscapeResult {
      var byte: UInt8 = 0
      guard read(STDIN_FILENO, &byte, 1) == 1 else {
        return .unknown
      }
      switch byte {
        case UInt8(ascii: "["):
          // CSI sequence — read the final byte
          guard read(STDIN_FILENO, &byte, 1) == 1 else { return .unknown }
          // Drain extended sequences e.g. ESC [ 1 ~
          if byte >= UInt8(ascii: "0") && byte <= UInt8(ascii: "9") {
            var extra: UInt8 = 0
            _ = read(STDIN_FILENO, &extra, 1)
            return .unknown
          }
          switch byte {
            case UInt8(ascii: "A"):
              return .arrowUp
            case UInt8(ascii: "B"):
              return .arrowDown
            case UInt8(ascii: "C"):
              return .arrowRight
            case UInt8(ascii: "D"):
              return .arrowLeft
            default:
              return .unknown
          }
        default:
          return .unknown
      }
    }

    // Move terminal cursor left by `n` columns.
    func cursorLeft(_ n: Int) {
      guard n > 0 else { return }
      print("\u{1B}[\(n)D", terminator: "")
      fflush(stdout)
    }

    // Move terminal cursor right by `n` columns.
    func cursorRight(_ n: Int) {
      guard n > 0 else { return }
      print("\u{1B}[\(n)C", terminator: "")
      fflush(stdout)
    }

    // Redraws all '*' from `cursorIndex` to end, then repositions cursor.
    // Called after any insertion or deletion in the middle of the string.
    func redrawFromCursor(clusterWidths: [Int], cursorIndex: Int, eraseTrailing: Bool = false) {
      // On insert: suffix grew by 1, print suffixCount+1 stars, move back suffixCount
      // On delete: suffix shrank by 1, print suffixCount stars + 1 space, move back suffixCount+1
      let suffixCount = clusterWidths.count - cursorIndex
      if eraseTrailing {
        // Deletion: overwrite old stars with new (fewer) stars, blank the last one
        print(String(repeating: replacementChar, count: suffixCount), terminator: "")
        print(" ", terminator: "")
        fflush(stdout)
        cursorLeft(suffixCount + 1)
      } else {
        // Insertion: overwrite old stars and add one new one at the end
        print(String(repeating: replacementChar, count: suffixCount + 1), terminator: "")
        fflush(stdout)
        cursorLeft(suffixCount)
      }
    }
    
    // Each element corresponds to one grapheme cluster (character typed by user).
    var clusterBytes:  [[UInt8]] = []   // raw UTF-8 bytes per cluster
    var clusterWidths: [Int]     = []   // terminal column width per cluster
    var cursorIndex: Int = 0            // insertion point (0 = before first char)
    
    while true {
      guard let (scalar, bytes) = readUnicodeScalar() else {
        break
      }
      switch scalar.value {
        // Enter/Return
        case 10, 13:
          if !allowEmpty && clusterBytes.isEmpty {
            print("\u{07}", terminator: "")  // BEL — signal that empty is not allowed
            fflush(stdout)
            continue
          }
        // Ctrl+A — jump to beginning
        case 0x01:
          if cursorIndex > 0 {
            let cols = clusterWidths[..<cursorIndex].reduce(0, +)
            cursorLeft(cols)
            cursorIndex = 0
          }
          continue
        // Ctrl+E — jump to end
        case 0x05:
          if cursorIndex < clusterWidths.count {
            let cols = clusterWidths[cursorIndex...].reduce(0, +)
            cursorRight(cols)
            cursorIndex = clusterWidths.count
          }
          continue
        // ESC — start of arrow-key sequence
        case 0x1B:
          switch readEscapeSequence() {
            case .arrowLeft:
              if cursorIndex > 0 {
                cursorIndex -= 1
                cursorLeft(clusterWidths[cursorIndex])
              }
            case .arrowRight:
              if cursorIndex < clusterWidths.count {
                cursorRight(clusterWidths[cursorIndex])
                cursorIndex += 1
              }
            case .arrowUp, .arrowDown:
              print("\u{07}", terminator: "") // BEL
              fflush(stdout)
              break
            case .unknown:
              break
          }
          continue
        // Backspace/DEL — delete character before cursor
        case 127, 8:
          guard cursorIndex > 0 else {
            continue
          }
          cursorIndex -= 1
          let w = clusterWidths[cursorIndex]
          clusterBytes.remove(at: cursorIndex)
          clusterWidths.remove(at: cursorIndex)
          cursorLeft(w)
          redrawFromCursor(clusterWidths: clusterWidths, cursorIndex: cursorIndex, eraseTrailing: true)
          continue
        // Ctrl+C
        case 3:
          tcsetattr(STDIN_FILENO, TCSANOW, &originalTermios)
          throw LineReaderError.CTRLC
        // Ctrl+U — clear entire line
        case 21:
          // Move cursor to start of input, erase all stars
          let colsToStart = clusterWidths[..<cursorIndex].reduce(0, +)
          cursorLeft(colsToStart)
          let totalStars = clusterWidths.count
          print(String(repeating: " ", count: totalStars), terminator: "")
          cursorLeft(totalStars)
          clusterBytes.removeAll()
          clusterWidths.removeAll()
          cursorIndex = 0
          fflush(stdout)
          continue
        // Printable character
        default:
          let w = terminalWidth(of: scalar)
          if w == 0 {             // skip zero-width / control scalars
            continue              // Accumulate bytes until we have a full grapheme cluster.
          }                       // For password input a single scalar per cluster is fine.
                                  // Enforce maxLength if specified
          if let max = maxLength, clusterWidths.count >= max {
            print("\u{07}", terminator: "")  // BEL
            fflush(stdout)
            continue
          }
          // Insert at cursorIndex
          clusterBytes.insert(bytes, at: cursorIndex)
          clusterWidths.insert(w, at: cursorIndex)
          cursorIndex += 1
          if cursorIndex == clusterWidths.count {
            // Cursor is at the end — simple append, no redraw needed
            print("\(replacementChar)", terminator: "")
            fflush(stdout)
          } else {
            // Cursor is in the middle — redraw stars from insertion point
            redrawFromCursor(clusterWidths: clusterWidths, cursorIndex: cursorIndex, eraseTrailing: false)
          }
          continue
      }
      break
    }
    return String(bytes: clusterBytes.flatMap { $0 }, encoding: .utf8) ?? ""
  }
  
  /// Returns the current size of the terminal in terms of a tuple whose
  /// first component refers to the number of lines, and whose second
  /// component refers to the number of columns.
  public static var size: (lines: Int, columns: Int)? {
    var ws = winsize()
    if ioctl(STDOUT_FILENO, UInt(TIOCGWINSZ), &ws) >= 0, ws.ws_col > 0 {
      return (lines: Int(ws.ws_row), columns: Int(ws.ws_col))
    }
    return nil
  }
  
  /// Current terminal identifier
  public static let current: String = ProcessInfo.processInfo.environment["TERM"] ?? ""
  
  /// Does the current terminal support full color mode?
  public static var fullColorSupport: Bool {
    // First make sure we are not running within Xcode
    guard ProcessInfo.processInfo.environment["__XCODE_BUILT_PRODUCTS_DIR_PATHS"] == nil else {
      return false
    }
    // Next, check if there is an environment variable COLORTERM set to "truecolor"
    if let cterm = ProcessInfo.processInfo.environment["COLORTERM"], cterm == "truecolor" {
      return true
    }
    // Finally, apply some heuristics based on the current terminal
    return Terminal.fullColorSupport(terminal: Terminal.current)
  }
  
  /// Does the given terminal support full color?
  public static func fullColorSupport(terminal: String) -> Bool {
    // A rather dumb way of detecting colour support
    return terminal.contains("256")
  }
  
  // Colour tables from https://jonasjacek.github.io/colors/
  // Format: (r, g, b)
  
  private static let colors: [(UInt8, UInt8, UInt8)] = [
    // Standard
    (0, 0, 0), (128, 0, 0), (0, 128, 0), (128, 128, 0), (0, 0, 128), (128, 0, 128),
    (0, 128, 128), (192, 192, 192),
    // High intensity
    (128, 128, 128), (255, 0, 0), (0, 255, 0), (255, 255, 0), (0, 0, 255), (255, 0, 255),
    (0, 255, 255), (255, 255, 255),
    // 256 color extended
    (0, 0, 0), (0, 0, 95), (0, 0, 135), (0, 0, 175), (0, 0, 215), (0, 0, 255), (0, 95, 0),
    (0, 95, 95), (0, 95, 135), (0, 95, 175), (0, 95, 215), (0, 95, 255), (0, 135, 0),
    (0, 135, 95), (0, 135, 135), (0, 135, 175), (0, 135, 215), (0, 135, 255), (0, 175, 0),
    (0, 175, 95), (0, 175, 135), (0, 175, 175), (0, 175, 215), (0, 175, 255), (0, 215, 0),
    (0, 215, 95), (0, 215, 135), (0, 215, 175), (0, 215, 215), (0, 215, 255), (0, 255, 0),
    (0, 255, 95), (0, 255, 135), (0, 255, 175), (0, 255, 215), (0, 255, 255), (95, 0, 0),
    (95, 0, 95), (95, 0, 135), (95, 0, 175), (95, 0, 215), (95, 0, 255), (95, 95, 0),
    (95, 95, 95), (95, 95, 135), (95, 95, 175), (95, 95, 215), (95, 95, 255), (95, 135, 0),
    (95, 135, 95), (95, 135, 135), (95, 135, 175), (95, 135, 215), (95, 135, 255), (95, 175, 0),
    (95, 175, 95), (95, 175, 135), (95, 175, 175), (95, 175, 215), (95, 175, 255), (95, 215, 0),
    (95, 215, 95), (95, 215, 135), (95, 215, 175), (95, 215, 215), (95, 215, 255), (95, 255, 0),
    (95, 255, 95), (95, 255, 135), (95, 255, 175), (95, 255, 215), (95, 255, 255), (135, 0, 0),
    (135, 0, 95), (135, 0, 135), (135, 0, 175), (135, 0, 215), (135, 0, 255), (135, 95, 0),
    (135, 95, 95), (135, 95, 135), (135, 95, 175), (135, 95, 215), (135, 95, 255), (135, 135, 0),
    (135, 135, 95), (135, 135, 135), (135, 135, 175), (135, 135, 215), (135, 135, 255),
    (135, 175, 0), (135, 175, 95), (135, 175, 135), (135, 175, 175), (135, 175, 215),
    (135, 175, 255), (135, 215, 0), (135, 215, 95), (135, 215, 135), (135, 215, 175),
    (135, 215, 215), (135, 215, 255), (135, 255, 0), (135, 255, 95), (135, 255, 135),
    (135, 255, 175), (135, 255, 215), (135, 255, 255), (175, 0, 0), (175, 0, 95), (175, 0, 135),
    (175, 0, 175), (175, 0, 215), (175, 0, 255), (175, 95, 0), (175, 95, 95), (175, 95, 135),
    (175, 95, 175), (175, 95, 215), (175, 95, 255), (175, 135, 0), (175, 135, 95),
    (175, 135, 135), (175, 135, 175), (175, 135, 215), (175, 135, 255), (175, 175, 0),
    (175, 175, 95), (175, 175, 135), (175, 175, 175), (175, 175, 215), (175, 175, 255),
    (175, 215, 0), (175, 215, 95), (175, 215, 135), (175, 215, 175), (175, 215, 215),
    (175, 215, 255), (175, 255, 0), (175, 255, 95), (175, 255, 135), (175, 255, 175),
    (175, 255, 215), (175, 255, 255), (215, 0, 0), (215, 0, 95), (215, 0, 135), (215, 0, 175),
    (215, 0, 215), (215, 0, 255), (215, 95, 0), (215, 95, 95), (215, 95, 135), (215, 95, 175),
    (215, 95, 215), (215, 95, 255), (215, 135, 0), (215, 135, 95), (215, 135, 135),
    (215, 135, 175), (215, 135, 215), (215, 135, 255), (215, 175, 0), (215, 175, 95),
    (215, 175, 135), (215, 175, 175), (215, 175, 215), (215, 175, 255), (215, 215, 0),
    (215, 215, 95), (215, 215, 135), (215, 215, 175), (215, 215, 215), (215, 215, 255),
    (215, 255, 0), (215, 255, 95), (215, 255, 135), (215, 255, 175), (215, 255, 215),
    (215, 255, 255), (255, 0, 0), (255, 0, 95), (255, 0, 135), (255, 0, 175), (255, 0, 215),
    (255, 0, 255), (255, 95, 0), (255, 95, 95), (255, 95, 135), (255, 95, 175), (255, 95, 215),
    (255, 95, 255), (255, 135, 0), (255, 135, 95), (255, 135, 135), (255, 135, 175),
    (255, 135, 215), (255, 135, 255), (255, 175, 0), (255, 175, 95), (255, 175, 135),
    (255, 175, 175), (255, 175, 215), (255, 175, 255), (255, 215, 0), (255, 215, 95),
    (255, 215, 135), (255, 215, 175), (255, 215, 215), (255, 215, 255), (255, 255, 0),
    (255, 255, 95), (255, 255, 135), (255, 255, 175), (255, 255, 215), (255, 255, 255),
    (8, 8, 8), (18, 18, 18), (28, 28, 28), (38, 38, 38), (48, 48, 48), (58, 58, 58),
    (68, 68, 68), (78, 78, 78), (88, 88, 88), (98, 98, 98), (108, 108, 108), (118, 118, 118),
    (128, 128, 128), (138, 138, 138), (148, 148, 148), (158, 158, 158), (168, 168, 168),
    (178, 178, 178), (188, 188, 188), (198, 198, 198), (208, 208, 208), (218, 218, 218),
    (228, 228, 228), (238, 238, 238)
  ]
  
  internal static func closestColor(to targetColor: (UInt8, UInt8, UInt8),
                                    fullColorSupport all256: Bool = false) -> UInt8 {
    let colorTable: [(UInt8, UInt8, UInt8)] = all256 ? colors : Array(colors[0..<8])
    let distances = colorTable.map {
      sqrt(pow(Double(Int($0.0) - Int(targetColor.0)), 2) +
           pow(Double(Int($0.1) - Int(targetColor.1)), 2) +
           pow(Double(Int($0.2) - Int(targetColor.2)), 2))
    }
    var closest = Double.greatestFiniteMagnitude
    var closestIdx = 0
    for i in 0..<distances.count {
      if distances[i] < closest  {
        closest = distances[i]
        closestIdx = i
      }
    }
    return UInt8(closestIdx)
  }
  
  internal static func isWideCharacter(_ value: UInt32) -> Bool {
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
