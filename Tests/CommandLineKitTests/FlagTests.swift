//
//  FlagTests.swift
//  CommandLineKitTests
//
//  Created by Matthias Zenger on 25/03/2017.
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
