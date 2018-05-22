//
//  FlagTests.swift
//  CommandLineKitTests
//
//  Created by Matthias Zenger on 25/03/2017.
//  Copyright © 2018 Google LLC
//
//  Use of this source code is governed by a BSD-style
//  license that can be found in the LICENSE file or at
//  https://developers.google.com/open-source/licenses/bsd
//

import XCTest
@testable import CommandLineKit

class FlagTests: XCTestCase {
  
  override func setUp() {
    super.setUp()
  }
  
  override func tearDown() {
    super.tearDown()
  }
  
  func testLongFlagNames2() throws {
    let flags = Flags(["--one", "--four", "912", "--three", "--five", "-3.141",
                       "--six", "six", "seven"])
    let one = flags.option(nil, "one", description: "the one option")
    let two = flags.option(nil, "two", description: "the two option")
    let three = flags.option(nil, "three", description: "the three option")
    let four = flags.argument(nil, "four", description: "the four option for ints", value: 0)
    let five = flags.double(nil, "five", description: "the five option for doubles")
    let six = flags.string(nil, "six", description: "the six option for strings")
    let seven = flags.string(nil, "seven", description: "the seven option for strings")
    try flags.parse()
    XCTAssert(one.wasSet)
    XCTAssert(!two.wasSet)
    XCTAssert(three.wasSet)
    XCTAssert(four.value != nil && four.value! == 912)
    XCTAssert(five.value != nil && five.value! == -3.141)
    XCTAssert(six.value != nil && six.value! == "six")
    XCTAssertNil(seven.value)
    XCTAssert(flags.parameters.count == 1 && flags.parameters[0] == "seven")
  }
  
  func testLongFlagNames() throws {
    let flags = Flags(["--one", "--four", "912", "--three", "--five", "-3.141",
                       "--six", "six", "seven"])
    let one = flags.option(nil, "one", description: "the one option")
    let two = flags.option(nil, "two", description: "the two option")
    let three = flags.option(nil, "three", description: "the three option")
    let four = flags.int(nil, "four", description: "the four option for ints")
    let five = flags.double(nil, "five", description: "the five option for doubles")
    let six = flags.string(nil, "six", description: "the six option for strings")
    let seven = flags.string(nil, "seven", description: "the seven option for strings")
    try flags.parse()
    XCTAssert(one.wasSet)
    XCTAssert(!two.wasSet)
    XCTAssert(three.wasSet)
    XCTAssert(four.value != nil && four.value! == 912)
    XCTAssert(five.value != nil && five.value! == -3.141)
    XCTAssert(six.value != nil && six.value! == "six")
    XCTAssertNil(seven.value)
    XCTAssert(flags.parameters.count == 1 && flags.parameters[0] == "seven")
  }
  
  func testShortFlagNames() throws {
    let flags = Flags(["-a", "-d", "912", "-c", "-e", "-3.141",
                       "-f", "six", "seven"])
    let one = flags.option("a", description: "the one option")
    let two = flags.option("b", description: "the two option")
    let three = flags.option("c", description: "the three option")
    let four = flags.int("d", description: "the four option for ints")
    let five = flags.double("e", description: "the five option for doubles")
    let six = flags.string("f", description: "the six option for strings")
    let seven = flags.string("g", description: "the seven option for strings")
    try flags.parse()
    XCTAssert(one.wasSet)
    XCTAssert(!two.wasSet)
    XCTAssert(three.wasSet)
    XCTAssert(four.value != nil && four.value! == 912)
    XCTAssert(five.value != nil && five.value! == -3.141)
    XCTAssert(six.value != nil && six.value! == "six")
    XCTAssertNil(seven.value)
    XCTAssert(flags.parameters.count == 1 && flags.parameters[0] == "seven")
  }
}
