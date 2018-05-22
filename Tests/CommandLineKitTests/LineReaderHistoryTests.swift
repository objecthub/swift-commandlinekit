//
//  LineReaderHistoryTests.swift
//  CommandLineKitTests
//
//  Created by Matthias Zenger on 08/04/2018.
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

import XCTest
@testable import CommandLineKit

class LineReaderHistoryTests: XCTestCase {
  func testHistoryAddItem() {
    let h = LineReaderHistory()
    h.add("Test")
    XCTAssertEqual(h.historyItems, ["Test"])
  }
  
  func testHistoryDoesNotAddDuplicatedLines() {
    let h = LineReaderHistory()
    h.add("Test")
    h.add("Test")
    XCTAssertEqual(h.historyItems.count, 1)
    // Test adding a new item in-between doesn't de-dupe the newest line
    h.add("Test 2")
    h.add("Test")
    XCTAssertEqual(h.historyItems.count, 3)
  }
  
  func testHistoryHonorsMaxLength() {
    let h = LineReaderHistory()
    h.maxLength = 2
    h.add("Test 1")
    h.add("Test 2")
    h.add("Test 3")
    XCTAssertEqual(h.historyItems.count, 2)
    XCTAssertEqual(h.historyItems, ["Test 2", "Test 3"])
  }
  
  func testHistoryRemovesEntriesWhenMaxLengthIsSet() {
    let h = LineReaderHistory()
    h.add("Test 1")
    h.add("Test 2")
    h.add("Test 3")
    XCTAssertEqual(h.historyItems.count, 3)
    h.maxLength = 2
    XCTAssertEqual(h.historyItems.count, 2)
    XCTAssertEqual(h.historyItems, ["Test 2", "Test 3"])
  }
  
  func testHistoryNavigationReturnsNilWhenHistoryEmpty() {
    let h = LineReaderHistory()
    XCTAssertNil(h.navigateHistory(direction: .next))
    XCTAssertNil(h.navigateHistory(direction: .previous))
  }
  
  func testHistoryNavigationReturnsSingleItemWhenHistoryHasOneItem() {
    let h = LineReaderHistory()
    h.add("Test")
    XCTAssertNil(h.navigateHistory(direction: .next))
    guard let previousItem = h.navigateHistory(direction: .previous) else {
      XCTFail("Expected previous item to not be nil")
      return
    }
    XCTAssertEqual(previousItem, "Test")
  }
  
  func testHistoryStopsAtBeginning() {
    let h = LineReaderHistory()
    h.add("1")
    h.add("2")
    h.add("3")
    XCTAssertEqual(h.navigateHistory(direction: .previous), "3")
    XCTAssertEqual(h.navigateHistory(direction: .previous), "2")
    XCTAssertEqual(h.navigateHistory(direction: .previous), "1")
    XCTAssertNil(h.navigateHistory(direction: .previous))
  }
  
  func testHistoryNavigationStopsAtEnd() {
    let h = LineReaderHistory()
    h.add("1")
    h.add("2")
    h.add("3")
    XCTAssertNil(h.navigateHistory(direction: .next))
  }
  
  func testHistorySavesToFile() {
    let h = LineReaderHistory()
    h.add("Test 1")
    h.add("Test 2")
    h.add("Test 3")
    let tempFile = "/tmp/linereaderhistory_save_test.txt"
    do {
      try h.save(toFile: tempFile)
    } catch {
      XCTFail("Saving file should not throw exception")
    }
    let fileContents: String
    do {
      fileContents = try String(contentsOfFile: tempFile, encoding: .utf8)
    } catch {
      XCTFail("Loading file should not throw exception")
      return
    }
    // Reading the file should yield the same lines as input
    let items = fileContents.split(separator: "\n")
    XCTAssertEqual(items, ["Test 1", "Test 2", "Test 3"])
  }
  
  func testHistoryLoadsFromFile() {
    let h = LineReaderHistory()
    let tempFile = "/tmp/linereaderhistory_load_test.txt"
    do {
      try "Test 1\nTest 2\nTest 3".write(toFile: tempFile, atomically: true, encoding: .utf8)
    } catch {
      XCTFail("Writing file should not throw exception")
    }
    do {
      try h.load(fromFile: tempFile)
    } catch {
      XCTFail("Loading file should not throw exception")
      return
    }
    XCTAssertEqual(h.historyItems.count, 3)
    XCTAssertEqual(h.historyItems, ["Test 1", "Test 2", "Test 3"])
  }
  
  func testHistoryLoadingRespectsMaxLength() {
    let h = LineReaderHistory()
    h.maxLength = 2
    let tempFile = "/tmp/linereaderhistory_load_test.txt"
    do {
      try "Test 1\nTest 2\nTest 3".write(toFile: tempFile, atomically: true, encoding: .utf8)
    } catch {
      XCTFail("Writing file should not throw exception")
    }
    do {
      try h.load(fromFile: tempFile)
    } catch {
      XCTFail("Loading file should not throw exception")
      return
    }
    XCTAssertEqual(h.historyItems.count, 2)
    XCTAssertEqual(h.historyItems, ["Test 2", "Test 3"])
  }
}
