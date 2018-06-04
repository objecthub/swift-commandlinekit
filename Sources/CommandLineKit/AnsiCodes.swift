//
//  AnsiCodes.swift
//  CommandLineKit
//
//  Created by Matthias Zenger on 07/04/2018.
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

import Foundation

public struct AnsiCodes {
  public static let CSI: String = "\u{001B}["
  
  public static let eraseRight: String = escapeCode("0K")
  public static let homeCursor: String = escapeCode("H")
  
  /// The following line is a hack. It is the only reliable way I could get "Terminal.app" on
  /// macOS to return to the beginning of the line
  public static let beginningOfLine: String = cursorBackward(3000) + cursorBackward(999)
  public static let endOfLine: String = cursorForward(3000) + cursorForward(999)
  
  /// Clear screen
  public static let clearScreen: String = escapeCode("2J")
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
  
  public static func setCursorColumn(_ column: Int) -> String {
    return escapeCode("\(column)G")
  }
  
  public static func setCursorPos(_ row: Int, _ column: Int) -> String {
    return escapeCode("\(row);\(column)H")
  }
  
  public static func cursorUp(_ rows: Int) -> String {
    guard rows > 0 else {
      return ""
    }
    return escapeCode("\(rows)A")
  }
  
  public static func cursorDown(_ rows: Int) -> String {
    guard rows > 0 else {
      return ""
    }
    return escapeCode("\(rows)B")
  }
  
  public static func cursorForward(_ columns: Int) -> String {
    guard columns > 0 else {
      return ""
    }
    return escapeCode("\(columns)C")
  }
  
  public static func cursorBackward(_ columns: Int) -> String {
    guard columns > 0 else {
      return ""
    }
    return escapeCode("\(columns)D")
  }
  
  public static func nextLine(_ lines: Int) -> String {
    return escapeCode("\(lines)E")
  }
  
  public static func previousLine(_ lines: Int) -> String {
    return escapeCode("\(lines)F")
  }
  
  public static func termColor(color: Int, bold: Bool) -> String {
    return escapeCode("\(color);\(bold ? 1 : 0);49m")
  }
  
  public static func termColor256(color: Int) -> String {
    return escapeCode("38;5;\(color)m")
  }
}
