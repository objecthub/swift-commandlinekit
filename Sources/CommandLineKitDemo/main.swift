//
//  main.swift
//  CommandLineKitDemo
//
//  Created by Matthias Zenger on 08/04/2018.
//  Copyright © 2018 Google LLC
//
//  Use of this source code is governed by a BSD-style
//  license that can be found in the LICENSE file or at
//  https://developers.google.com/open-source/licenses/bsd
//

import Foundation
import CommandLineKit

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
  do {
    try ln.clearScreen()
  } catch {
    print(error)
  }
  print("Type 'exit' to quit")
  var done = false
  while !done {
    do {
      let output = try ln.readLine(prompt: "> ",
                                   maxCount: 200,
                                   promptProperties: TextProperties(.green, nil, .bold),
                                   readProperties: TextProperties(.blue, nil),
                                   parenProperties: TextProperties(.red, nil, .bold))
      print("\nOutput: \(output)")
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
