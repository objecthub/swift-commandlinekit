//
//  LineReader.swift
//  CommandLineKit
//
//  Created by Matthias Zenger on 07/04/2018.
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

import Foundation

public class LineReader {
  
  /// Does this terminal support this line reader?
  public let termSupported: Bool
  
  /// Terminal type
  public let currentTerm: String
  
  /// Does the terminal support colors?
  public let fullColorSupport: Bool
  
  /// If false (the default) any edits by the user to a line in the history will be discarded
  /// if the user moves forward or back in the history without pressing Enter. If true, all
  /// history edits will be preserved.
  public var preserveHistoryEdits = false
  
  /// The history of previous line reads
  private var history: LineReaderHistory
  
  /// Temporary line read buffer to handle browsing of histories
  private var tempBuf: String?
  
  /// A callback for handling line completions
  private var completionCallback: ((String) -> [String])?
  
  /// A callback for handling hints
  private var hintsCallback: ((String) -> (String, TextProperties)?)?
  
  /// A POSIX file handle for the input
  private let inputFile: Int32
  
  /// A POSIX file handle for the output
  private let outputFile: Int32
  
  /// Initializer
  public init?(inputFile: Int32 = STDIN_FILENO,
               outputFile: Int32 = STDOUT_FILENO,
               completionCallback: ((String) -> [String])? = nil,
               hintsCallback: ((String) -> (String, TextProperties)?)? = nil) {
    self.inputFile = inputFile
    self.outputFile = outputFile
    self.currentTerm = Terminal.current
    if isatty(inputFile) != 1 {
      return nil
    } else {
      self.termSupported = LineReader.readerSupport(termVar: self.currentTerm)
    }
    self.fullColorSupport = Terminal.fullColorSupport(termVar: self.currentTerm)
    self.history = LineReaderHistory()
    self.completionCallback = completionCallback
    self.hintsCallback = hintsCallback
  }
  
  private static func readerSupport(termVar: String) -> Bool {
    switch termVar {
      case "", "xcode", "dumb", "cons25", "emacs":
        return false
      default:
        return true
    }
  }
  
  /// Adds a string to the history buffer.
  public func addHistory(_ item: String) {
    self.history.add(item)
  }
  
  /// Adds a callback for tab completion. The callback is taking the current text and returning
  /// an array of Strings containing possible completions.
  public func setCompletionCallback(_ callback: @escaping (String) -> [String]) {
    self.completionCallback = callback
  }
  
  /// Adds a callback for hints as you type. The callback is taking the current text and
  /// optionally returning the hint and a tuple of RGB colours for the hint text.
  public func setHintsCallback(_ callback: @escaping (String) -> (String, TextProperties)?) {
    self.hintsCallback = callback
  }
  
  /// Loads history from a file and appends it to the current history buffer. This method can
  /// throw an error if the file cannot be found or loaded.
  public func loadHistory(fromFile path: String) throws {
    try self.history.load(fromFile: path)
  }
  
  /// Saves history to a file. This method can throw an error if the file cannot be written to.
  public func saveHistory(toFile path: String) throws {
    try self.history.save(toFile: path)
  }
  
  /// Sets the maximum amount of items to keep in history. If this limit is reached, the oldest
  /// item is discarded when a new item is added. Setting the maximum length of history to 0
  /// (the default) will keep unlimited items in history.
  public func setHistoryMaxLength(_ historyMaxLength: UInt) {
    self.history.maxLength = historyMaxLength
  }
  
  /// Clears the screen. This method can throw an error if the terminal cannot be written to.
  public func clearScreen() throws {
    if self.termSupported {
      try self.output(text: AnsiCodes.homeCursor)
      try self.output(text: AnsiCodes.clearScreen)
    }
  }
  
  /// The main function of LineReader. This method shows a prompt to the user at the beginning
  /// of the line and reads the input from the user, returning it as a string. The method can
  /// throw an error if the terminal cannot be written to.
  public func readLine(prompt: String,
                       maxCount: Int? = nil,
                       promptProperties: TextProperties = TextProperties.none,
                       readProperties: TextProperties = TextProperties.none,
                       parenProperties: TextProperties = TextProperties.none) throws -> String {
    tempBuf = nil
    if self.termSupported {
      return try self.readLineSupported(prompt: prompt,
                                        maxCount: maxCount,
                                        promptProperties: promptProperties,
                                        readProperties: readProperties,
                                        parenProperties: parenProperties)
    } else {
      return try self.readLineUnsupported(prompt: prompt, maxCount: maxCount)
    }
  }
  
  private func readLineUnsupported(prompt: String, maxCount: Int?) throws -> String {
    print(prompt, terminator: "")
    if let line = Swift.readLine() {
      return maxCount != nil ? String(line.prefix(maxCount!)) : line
    } else {
      throw LineReaderError.EOF
    }
  }
  
  private func readLineSupported(prompt: String,
                                 maxCount: Int?,
                                 promptProperties: TextProperties,
                                 readProperties: TextProperties,
                                 parenProperties: TextProperties) throws -> String {
    var line: String = ""
    try self.withRawMode {
      try self.output(text: promptProperties.apply(to: prompt))
      let editState = EditState(prompt: prompt,
                                maxCount: maxCount,
                                promptProperties: promptProperties,
                                readProperties: readProperties,
                                parenProperties: parenProperties)
      while true {
        guard var char = self.readByte() else {
          return
        }
        if char == ControlCharacters.Tab.rawValue && self.completionCallback != nil,
           let completionChar = try self.completeLine(editState: editState) {
          char = completionChar
        }
        if let rv = try self.handleCharacter(char, editState: editState) {
          line = rv
          return
        }
      }
    }
    return line
  }
  
  private func completeLine(editState: EditState) throws -> UInt8? {
    guard let completionCallback = self.completionCallback else {
      return nil
    }
    let completions = completionCallback(editState.buffer)
    guard completions.count > 0 else {
      self.ringBell()
      return nil
    }
    // Loop to handle inputs
    var completionIndex = 0
    while true {
      if completionIndex < completions.count {
        try editState.withTemporaryState {
          try self.setBuffer(editState: editState, new: completions[completionIndex])
        }
      } else {
        try refreshLine(editState: editState)
      }
      guard let char = self.readByte() else {
        return nil
      }
      switch char {
        case ControlCharacters.Tab.rawValue:
          // Move to next completion
          completionIndex = (completionIndex + 1) % (completions.count + 1)
          if completionIndex == completions.count {
            self.ringBell()
          }
        case ControlCharacters.Esc.rawValue:
          // Show the original buffer
          if completionIndex < completions.count {
            try refreshLine(editState: editState)
          }
          return char
        default:
          // Update the buffer and return
          if completionIndex < completions.count {
            try self.setBuffer(editState: editState, new: completions[completionIndex])
          }
          return char
      }
    }
  }
  
  private func handleCharacter(_ ch: UInt8, editState: EditState) throws -> String? {
    switch ch {
      case ControlCharacters.Enter.rawValue:
        try refreshLine(editState: editState, decorate: false)
        return editState.buffer
      case ControlCharacters.CtrlA.rawValue:
        try self.moveHome(editState: editState)
      case ControlCharacters.CtrlE.rawValue:
        try self.moveEnd(editState: editState)
      case ControlCharacters.CtrlB.rawValue:
        try self.moveLeft(editState: editState)
      case ControlCharacters.CtrlC.rawValue:
        // Throw an error so that CTRL+C can be handled by the caller
        throw LineReaderError.CTRLC
      case ControlCharacters.CtrlD.rawValue:
        // If there is a character at the right of the cursor, remove it
        if editState.eraseCharacterRight() {
          try self.refreshLine(editState: editState)
        } else {
          self.ringBell()
        }
      case ControlCharacters.CtrlP.rawValue:
        // Previous history item
        try self.moveHistory(editState: editState, direction: .previous)
      case ControlCharacters.CtrlN.rawValue:
        // Next history item
        try self.moveHistory(editState: editState, direction: .next)
      case ControlCharacters.CtrlL.rawValue:
        // Clear screen
        try self.clearScreen()
        try self.refreshLine(editState: editState)
      case ControlCharacters.CtrlT.rawValue:
        if editState.swapCharacterWithPrevious() {
          try refreshLine(editState: editState)
        } else {
          self.ringBell()
        }
      case ControlCharacters.CtrlU.rawValue:
        // Delete whole line
        try self.setBuffer(editState: editState, new: "")
      case ControlCharacters.CtrlK.rawValue:
        // Delete to the end of the line
        if editState.deleteToEndOfLine() {
          try self.refreshLine(editState: editState)
        } else {
          self.ringBell()
        }
      case ControlCharacters.CtrlW.rawValue:
        // Delete previous word
        if editState.deletePreviousWord() {
          try self.refreshLine(editState: editState)
        } else {
          self.ringBell()
        }
      case ControlCharacters.Backspace.rawValue:
        // Delete character
        if editState.backspace() {
          try self.refreshLine(editState: editState)
        } else {
          self.ringBell()
        }
      case ControlCharacters.Esc.rawValue:
        try self.handleEscapeCode(editState: editState)
      default:
        // Read unicode character and insert it at the cursor position using UTF8 encoding
        var scalar = UInt32(ch)
        if ch >> 7 == 0 {
          // done
        } else if ch >> 5 == 0x6 {
          let ch2 = self.forceReadByte()
          scalar = (UInt32(ch & 0x1F) << 6) | UInt32(ch2 & 0x3F)
        } else if ch >> 4 == 0xE {
          let ch2 = self.forceReadByte()
          let ch3 = self.forceReadByte()
          scalar = (UInt32(ch & 0xF) << 12) | (UInt32(ch2 & 0x3F) << 6) | UInt32(ch3 & 0x3F)
        } else if ch >> 3 == 0x1E {
          let ch2 = self.forceReadByte()
          let ch3 = self.forceReadByte()
          let ch4 = self.forceReadByte()
          scalar = (UInt32(ch & 0x7) << 18) |
                   (UInt32(ch2 & 0x3F) << 12) |
                   (UInt32(ch3 & 0x3F) << 6) |
                   UInt32(ch4 & 0x3F)
        }
        let char = Character(UnicodeScalar(scalar) ?? UnicodeScalar(" "))
        if editState.insertCharacter(char) {
          try refreshLine(editState: editState)
        } else {
          self.ringBell()
        }
        if self.bytesAvailable > 0 {
          self.ringBell()
        }
    }
    return nil
  }
  
  private func handleEscapeCode(editState: EditState) throws {
    let fst = self.readCharacter()
    switch fst {
      case "[":
        let snd = self.readCharacter()
        switch snd {
          // Handle multi-byte sequence ^[[0...
          case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
            let trd = self.readCharacter()
            switch trd {
              case "~":
                switch snd {
                  case "1", "7":
                    try self.moveHome(editState: editState)
                  case "3":
                    try self.deleteCharacter(editState: editState)
                  case "4":
                    try self.moveEnd(editState: editState)
                  default:
                    break
                }
              case ";":
                let fot = self.readCharacter()
                let fth = self.readCharacter()
                // Shift
                if fot == "2" {
                  switch fth {
                    case "C":
                      try self.moveRight(editState: editState)
                    case "D":
                      try self.moveLeft(editState: editState)
                    default:
                      break
                  }
                }
                break
              case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
                _ = self.readCharacter()
                // ignore these codes for now
                break
              default:
                break
            }
          // ^[...
          case "A":
            try self.moveHistory(editState: editState, direction: .previous)
          case "B":
            try self.moveHistory(editState: editState, direction: .next)
          case "C":
            try self.moveRight(editState: editState)
          case "D":
            try self.moveLeft(editState: editState)
          case "H":
            try self.moveHome(editState: editState)
          case "F":
            try self.moveEnd(editState: editState)
          default:
            break
        }
      case "O":
        // ^[O...
        let snd = self.readCharacter()
        switch snd {
          case "H":
            try self.moveHome(editState: editState)
          case "F":
            try self.moveEnd(editState: editState)
          case "P":
            // F1
            break
          case "Q":
            // F2
            break
          case "R":
            // F3
            break
          case "S":
            // F4
            break
          default:
            break
        }
      case "b":
        // Alt+Left
        try self.moveToWordStart(editState: editState)
      case "f":
        // Alt+Right
        try self.moveToWordEnd(editState: editState)
      default:
        break
    }
  }
  
  private var cursorColumn: Int? {
    do {
      try self.output(text: AnsiCodes.cursorLocation)
    } catch {
      return nil
    }
    var buf = [UInt8]()
    var i = 0
    while true {
      if let c = self.readByte() {
        buf[i] = c
      } else {
        return nil
      }
      if buf[i] == 82 { // "R"
        break
      }
      i += 1
    }
    // Check the first characters are the escape code
    if buf[0] != 0x1B || buf[1] != 0x5B {
      return nil
    }
    let positionText = String(bytes: buf[2..<buf.count], encoding: .utf8)
    guard let rowCol = positionText?.split(separator: ";") else {
      return nil
    }
    if rowCol.count != 2 {
      return nil
    }
    return Int(String(rowCol[1]))
  }
  
  private var numColumns: Int {
    var winSize = winsize()
    if ioctl(1, UInt(TIOCGWINSZ), &winSize) == -1 || winSize.ws_col == 0 {
      return 80
    } else {
      return Int(winSize.ws_col)
    }
  }
  
  /// This constant is unfortunately not defined right now for usage in Swift; it is specific
  /// to macOS. Thus, this code is not portable!
  private static let FIONREAD: UInt = 0x4004667f
  
  private var bytesAvailable: Int {
    var available: Int = 0
    guard ioctl(self.inputFile, LineReader.FIONREAD, &available) >= 0 else {
      return 0
    }
    return available
  }
  
  private func updateCursorPos(editState: EditState) throws {
    if editState.requiresMatching() {
      try self.refreshLine(editState: editState)
    } else {
      let cursorWidth = editState.cursorWidth
      let numColumns = self.numColumns
      let cursorRows = cursorWidth / numColumns
      let cursorCols = cursorWidth % numColumns
      var commandBuf = AnsiCodes.beginningOfLine
      commandBuf += AnsiCodes.cursorDown(cursorRows)
      commandBuf += AnsiCodes.cursorForward(cursorCols)
      try self.output(text: commandBuf)
    }
  }
  
  private func refreshLine(editState: EditState, decorate: Bool = true) throws {
    let cursorWidth = editState.cursorWidth
    let numColumns = self.numColumns
    let cursorRows = cursorWidth / numColumns
    let cursorCols = cursorWidth % numColumns
    var commandBuf = AnsiCodes.beginningOfLine +
                     editState.promptProperties.apply(to: editState.prompt)
    if decorate, let idx = editState.matchingParen() {
      var fst = editState.buffer.index(before: editState.location)
      var snd = idx
      if fst > snd {
        snd = fst
        fst = idx
      }
      let one = String(editState.buffer.prefix(upTo: fst))
      let two = String(editState.buffer[editState.buffer.index(after: fst)..<snd])
      let three = String(editState.buffer.suffix(from: editState.buffer.index(after: snd)))
      let highlightProperties = editState.readProperties.with(editState.parenProperties)
      commandBuf += editState.readProperties.apply(to: one)
      commandBuf += highlightProperties.apply(to: String(editState.buffer[fst]))
      commandBuf += editState.readProperties.apply(to: two)
      commandBuf += highlightProperties.apply(to: String(editState.buffer[snd]))
      commandBuf += editState.readProperties.apply(to: three)
    } else {
      commandBuf += editState.readProperties.apply(to: editState.buffer)
    }
    let hints = decorate ? try self.refreshHints(editState: editState) : ""
    commandBuf += hints.isEmpty ? " " : hints
    commandBuf += AnsiCodes.clearCursorToBottom +
                  AnsiCodes.beginningOfLine +
                  AnsiCodes.cursorDown(cursorRows) +
                  AnsiCodes.cursorForward(cursorCols)
    try self.output(text: commandBuf)
  }
  
  private func readByte() -> UInt8? {
    var input: UInt8 = 0
    if read(self.inputFile, &input, 1) == 0 {
      return nil
    }
    return input
  }
  
  private func forceReadByte() -> UInt8 {
    var input: UInt8 = 0
    _ = read(self.inputFile, &input, 1)
    return input
  }
  
  private func readCharacter() -> Character? {
    var input: UInt8 = 0
    _ = read(self.inputFile, &input, 1)
    return Character(UnicodeScalar(input))
  }
  
  private func ringBell() {
    do {
      try self.output(character: ControlCharacters.Bell.character)
    } catch {
      // ignore failure
    }
  }
  
  private func output(character: ControlCharacters) throws {
    try self.output(character: character.character)
  }
  
  private func output(character: Character) throws {
    try self.output(text: String(character))
  }
  
  private func output(text: String) throws {
    if write(outputFile, text, text.utf8.count) == -1 {
      throw LineReaderError.generalError("Unable to write to output")
    }
  }
  
  private func setBuffer(editState: EditState, new buffer: String) throws {
    if editState.setBuffer(buffer) {
      _ = editState.moveEnd()
      try self.refreshLine(editState: editState)
    } else {
      self.ringBell()
    }
  }
  
  private func moveLeft(editState: EditState) throws {
    if editState.moveLeft() {
      try self.updateCursorPos(editState: editState)
    } else {
      self.ringBell()
    }
  }
  
  private func moveRight(editState: EditState) throws {
    if editState.moveRight() {
      try self.updateCursorPos(editState: editState)
    } else {
      self.ringBell()
    }
  }
  
  private func moveHome(editState: EditState) throws {
    if editState.moveHome() {
      try self.updateCursorPos(editState: editState)
    } else {
      self.ringBell()
    }
  }
  
  private func moveEnd(editState: EditState) throws {
    if editState.moveEnd() {
      try self.updateCursorPos(editState: editState)
    } else {
      self.ringBell()
    }
  }
 
  private func moveToWordStart(editState: EditState) throws {
    if editState.moveToWordStart() {
      try self.updateCursorPos(editState: editState)
    } else {
      self.ringBell()
    }
  }
  
  private func moveToWordEnd(editState: EditState) throws {
    if editState.moveToWordEnd() {
      try self.updateCursorPos(editState: editState)
    } else {
      self.ringBell()
    }
  }
  
  private func deleteCharacter(editState: EditState) throws {
    if editState.deleteCharacter() {
      try self.refreshLine(editState: editState)
    } else {
      self.ringBell()
    }
  }
  
  private func moveHistory(editState: EditState,
                           direction: LineReaderHistory.HistoryDirection) throws {
    // If we're at the end of history (editing the current line), push it into a temporary
    // buffer so it can be retrieved later
    if self.history.currentIndex == self.history.historyItems.count {
      tempBuf = editState.buffer
    } else if self.preserveHistoryEdits {
      self.history.replaceCurrent(editState.buffer)
    }
    if let historyItem = self.history.navigateHistory(direction: direction) {
      try self.setBuffer(editState: editState, new: historyItem)
    } else if case .next = direction {
      try self.setBuffer(editState: editState, new: tempBuf ?? "")
    } else {
      self.ringBell()
    }
  }
  
  private func refreshHints(editState: EditState) throws -> String {
    guard let hintsCallback = self.hintsCallback,
          let (hint, properties) = hintsCallback(editState.buffer) else {
      return ""
    }
    let currentLineLength = editState.prompt.count + editState.buffer.count
    if hint.count + currentLineLength > self.numColumns {
      return ""
    } else {
      return properties.apply(to: hint) + AnsiCodes.origTermColor
    }
  }
  
  private func withRawMode(body: () throws -> ()) throws {
    var originalTermios: termios = termios()
    defer {
      _ = tcsetattr(self.inputFile, TCSADRAIN, &originalTermios)
    }
    if tcgetattr(self.inputFile, &originalTermios) == -1 {
      throw LineReaderError.generalError("could not get term attributes")
    }
    var raw = originalTermios
    raw.c_iflag &= ~UInt(BRKINT | ICRNL | INPCK | ISTRIP | IXON)
    raw.c_oflag &= ~UInt(OPOST)
    raw.c_cflag |= UInt(CS8)
    raw.c_lflag &= ~UInt(ECHO | ICANON | IEXTEN | ISIG)
    // VMIN = 16
    raw.c_cc.16 = 1
    guard tcsetattr(self.inputFile, TCSADRAIN, &raw) >= 0 else {
      throw LineReaderError.generalError("Could not set raw mode")
    }
    try body()
  }
}
