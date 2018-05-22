//
//  EditState.swift
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

internal class EditState {
  let prompt: String
  let promptProperties: TextProperties
  let readProperties: TextProperties
  let parenProperties: TextProperties
  let maxCount: Int?
  var buffer: String
  var location: String.Index
  
  init(prompt: String,
       maxCount: Int? = nil,
       promptProperties: TextProperties = TextProperties.none,
       readProperties: TextProperties = TextProperties.none,
       parenProperties: TextProperties = TextProperties.none) {
    self.prompt = prompt
    self.promptProperties = promptProperties
    self.readProperties = readProperties
    self.parenProperties = parenProperties
    self.maxCount = maxCount
    self.buffer = ""
    self.location = buffer.endIndex
  }
  
  var cursorWidth: Int {
    return self.cursorPosition + self.prompt.count
  }
  
  var cursorPosition: Int {
    return self.buffer.distance(from: self.buffer.startIndex, to: self.location)
  }
  
  var cursorAtEnd: Bool {
    return self.location == self.buffer.endIndex
  }
  
  func insertCharacter(_ char: Character) -> Bool {
    if let max = self.maxCount, self.buffer.count >= max {
      return false
    }
    let origLoc = self.location
    let origEnd = self.buffer.endIndex
    self.buffer.insert(char, at: location)
    self.location = self.buffer.index(after: location)
    if origLoc == origEnd {
      self.location = self.buffer.endIndex
    }
    return true
  }
  
  func setBuffer(_ newBuffer: String, truncateIfNeeded: Bool = false) -> Bool {
    if let max = self.maxCount, newBuffer.count >= max {
      if truncateIfNeeded {
        self.buffer = String(newBuffer.prefix(max))
        return true
      } else {
        return false
      }
    } else {
      self.buffer = newBuffer
      return true
    }
  }
  
  func backspace() -> Bool {
    if self.location != self.buffer.startIndex {
      if self.location != self.buffer.startIndex {
        self.location = self.buffer.index(before: self.location)
      }
      self.buffer.remove(at: self.location)
      return true
    } else {
      return false
    }
  }
  
  func moveLeft() -> Bool {
    if self.location == self.buffer.startIndex {
      return false
    } else {
      self.location = self.buffer.index(before: self.location)
      return true
    }
  }
  
  func moveRight() -> Bool {
    if self.location == self.buffer.endIndex {
      return false
    } else {
      self.location = self.buffer.index(after: self.location)
      return true
    }
  }
  
  func moveHome() -> Bool {
    if self.location == self.buffer.startIndex {
      return false
    } else {
      self.location = self.buffer.startIndex
      return true
    }
  }
  
  func moveEnd() -> Bool {
    if self.location == self.buffer.endIndex {
      return false
    } else {
      self.location = self.buffer.endIndex
      return true
    }
  }
  
  func deleteCharacter() -> Bool {
    if self.location >= self.buffer.endIndex || self.buffer.isEmpty {
      return false
    } else {
      self.buffer.remove(at: self.location)
      return true
    }
  }
  
  func eraseCharacterRight() -> Bool {
    if self.buffer.count == 0 || self.location >= self.buffer.endIndex {
      return false
    } else {
      self.buffer.remove(at: self.location)
      if self.location > self.buffer.endIndex {
        self.location = self.buffer.endIndex
      }
      return true
    }
  }
  
  func deletePreviousWord() -> Bool {
    let oldLocation = self.location
    // Go backwards to find the first non space character
    while self.location > self.buffer.startIndex &&
          self.buffer[self.buffer.index(before: self.location)] == " " {
      self.location = self.buffer.index(before: self.location)
    }
    // Go backwards to find the next space character (start of the word)
    while self.location > self.buffer.startIndex &&
          self.buffer[self.buffer.index(before: self.location)] != " " {
      self.location = self.buffer.index(before: self.location)
    }
    if self.buffer.distance(from: oldLocation, to: self.location) == 0 {
      return false
    } else {
      self.buffer.removeSubrange(self.location..<oldLocation)
      return true
    }
  }
  
  func moveToWordStart() -> Bool {
    let oldLocation = self.location
    // Go backwards to find the first non space character
    while self.location > self.buffer.startIndex &&
          self.buffer[self.buffer.index(before: self.location)] == " " {
      self.location = self.buffer.index(before: self.location)
    }
    // Go backwards to find the next space character (start of the word)
    while self.location > self.buffer.startIndex &&
          self.buffer[self.buffer.index(before: self.location)] != " " {
      self.location = self.buffer.index(before: self.location)
    }
    return self.buffer.distance(from: oldLocation, to: self.location) != 0
  }
  
  func moveToWordEnd() -> Bool {
    let oldLocation = self.location
    // Go forward to find the first non space character
    while self.location < self.buffer.endIndex && self.buffer[self.location] == " " {
      self.location = self.buffer.index(after: self.location)
    }
    // Go forward to find the next space character (end of the word)
    while self.location < self.buffer.endIndex && self.buffer[self.location] != " " {
      self.location = self.buffer.index(after: self.location)
    }
    return self.buffer.distance(from: oldLocation, to: self.location) != 0
  }
  
  func deleteToEndOfLine() -> Bool {
    if self.location == self.buffer.endIndex || self.buffer.isEmpty {
      return false
    } else {
      self.buffer.removeLast(self.buffer.count - self.cursorPosition)
      return true
    }
  }
  
  func swapCharacterWithPrevious() -> Bool {
    if buffer.count < 2 {
      return false
    } else if self.location == self.buffer.endIndex {
      // Swap the two previous characters if at end index
      let temp = self.buffer.remove(at: self.buffer.index(self.location, offsetBy: -2))
      self.buffer.insert(temp, at: self.buffer.endIndex)
      self.location = self.buffer.endIndex
      return true
    } else if self.location > self.buffer.startIndex {
      // If the characters are in the middle of the string, swap character under cursor with
      // previous, then move the cursor to the right
      let temp = self.buffer.remove(at: self.buffer.index(before: self.location))
      self.buffer.insert(temp, at: self.location)
      if self.location < self.buffer.endIndex {
        self.location = buffer.index(after: self.location)
      }
      return true
    } else if self.location == self.buffer.startIndex {
      // If the character is at the start of the string, swap the first two characters, then
      // put the cursor after them
      let temp = self.buffer.remove(at: self.location)
      self.buffer.insert(temp, at: self.buffer.index(after: self.location))
      if self.location < self.buffer.endIndex {
        self.location = self.buffer.index(self.buffer.startIndex, offsetBy: 2)
      }
      return true
    } else {
      return false
    }
  }
  
  func requiresMatching() -> Bool {
    guard self.location > self.buffer.startIndex, !self.parenProperties.isEmpty else {
      return false
    }
    switch self.buffer[self.buffer.index(before: self.location)] {
      case "(", ")", "[", "]", "{", "}":
        return true
      default:
        return false
    }
  }
  
  func matchingParen() -> String.Index? {
    guard self.location > self.buffer.startIndex, !self.parenProperties.isEmpty else {
      return nil
    }
    var idx = self.buffer.index(before: self.location)
    let this: Character = self.buffer[idx]
    let other: Character
    let forward: Bool
    switch this {
      case "(":
        other = ")"
        forward = true
      case ")":
        other = "("
        forward = false
      case "[":
        other = "]"
        forward = true
      case "]":
        other = "["
        forward = false
      case "{":
        other = "}"
        forward = true
      case "}":
        other = "{"
        forward = false
      default:
        return nil
    }
    var open = 0
    if forward {
      idx = self.buffer.index(after: idx)
      while idx < self.buffer.endIndex && (open > 0 || self.buffer[idx] != other) {
        if self.buffer[idx] == this {
          open += 1
        } else if self.buffer[idx] == other {
          open -= 1
        }
        idx = self.buffer.index(after: idx)
      }
      if idx < self.buffer.endIndex && open == 0 {
        return idx
      }
    } else if idx > self.buffer.startIndex {
      idx = self.buffer.index(before: idx)
      while idx >= self.buffer.startIndex && (open > 0 || self.buffer[idx] != other) {
        if self.buffer[idx] == this {
          open += 1
        } else if self.buffer[idx] == other {
          open -= 1
        }
        guard idx > self.buffer.startIndex else {
          return nil
        }
        idx = self.buffer.index(before: idx)
      }
      if idx >= self.buffer.startIndex && open == 0 {
        return idx
      }
    }
    return nil
  }
  
  func withTemporaryState(_ body: () throws -> () ) throws {
    let originalBuffer = self.buffer
    let originalLocation = self.location
    try body()
    self.buffer = originalBuffer
    self.location = originalLocation
  }
}
