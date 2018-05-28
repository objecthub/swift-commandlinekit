//
//  main.swift
//  CommandLineKitDemo
//
//  Created by Matthias Zenger on 08/04/2018.
//  Copyright © 2018 Google LLC
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
import CommandLineKit

print("Detected terminal: \(Terminal.current)")
print(Terminal.fullColorSupport ? "Full color support" : "No color support")
print(LineReader.supportedByTerminal ? "LineReader support" : "No LineReader support")

if let ln = LineReader() {
  ln.setCompletionCallback { currentBuffer in
    let completions = [
      "Hello, world!",
      "Hello, Linenoise!",
      "Swift is Awesome!"
    ]
    return completions.filter { $0.hasPrefix(currentBuffer) }
  }
  ln.setHintsCallback { currentBuffer in
    let hints = [
      "Carpe Diem",
      "Lorem Ipsum",
      "Swift is Awesome!"
    ]
    let filtered = hints.filter { $0.hasPrefix(currentBuffer) }
    if let hint = filtered.first {
      let hintText = String(hint.dropFirst(currentBuffer.count))
      return (hintText, TextColor.grey.properties)
    } else {
      return nil
    }
  }
  print("Type 'exit' to quit")
  var done = false
  while !done {
    do {
      let output = try ln.readLine(prompt: "> ",
                                   maxCount: 200,
                                   strippingNewline: true,
                                   promptProperties: TextProperties(.green, nil, .bold),
                                   readProperties: TextProperties(.blue, nil),
                                   parenProperties: TextProperties(.red, nil, .bold))
      print("Entered: \(output)")
      ln.addHistory(output)
      if output == "exit" {
        break
      }
    } catch LineReaderError.CTRLC {
      print("\nCaptured CTRL+C. Quitting.")
      done = true
    } catch {
      print(error)
    }
  }
}
