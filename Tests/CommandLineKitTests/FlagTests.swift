//
//  FlagTests.swift
//  CommandLineKitTests
//
//  Created by Matthias Zenger on 25/03/2017.
//  Copyright © 2018-2023 Google LLC
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
  
  func testLongFlagNames2() throws {
    let flags = Flags(arguments: ["--one", "--four", "912", "--three", "--five", "-3.141",
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
    let flags = Flags(arguments: ["--one", "--four", "912", "--three", "--five", "-3.141",
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
    let flags = Flags(arguments: ["-a", "-d", "912", "-c", "-e", "-3.141",
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
  
  func testCommandFlags() throws {
    struct TestCommand: Command {
      static var executed = false
      static var flagsOk = false
      static var name: String {
        return "TestTool"
      }
      static var arguments: [String] {
        return ["--size", "23", "-h", "--repeated", "hello", "world", "!"]
      }
      @CommandOption(short: "h", description: "help") var help: Bool
      @CommandArgument(description: "count") var count: Int = 7
      @CommandArgument(description: "size") var size: Int?
      @CommandArguments(description: "repeated", maxCount: 3) var repeated: [String]
      @CommandParameters var params: [String]
      @CommandFlags var flags: Flags
      mutating func run() {
        TestCommand.executed = true
        TestCommand.flagsOk = self.size == 23 && self.help && self.repeated.count == 3 &&
                              self.flags.toolName == "TestTool"
      }
    }
    try TestCommand.main()
    XCTAssert(TestCommand.executed)
    XCTAssert(TestCommand.flagsOk)
  }
  
  func testCommandFlagsFailure() throws {
    struct TestCommand: Command {
      static var executed = false
      static var arguments: [String] {
        return ["--foo", "23"]
      }
      @CommandOption(short: "h", description: "help") var help: Bool
      @CommandArgument(description: "count") var count: Int = 7
      @CommandArgument(description: "size") var size: Int?
      @CommandArguments(description: "repeated", maxCount: 3) var repeated: [String]
      @CommandParameters var params: [String]
      @CommandFlags var flags: Flags
      mutating func fail(with: String) {
        TestCommand.executed = false
      }
      mutating func run() {
        TestCommand.executed = true
      }
    }
    try TestCommand.main()
    XCTAssert(!TestCommand.executed)
  }
  
  func testMoreCommandFlags() throws {
    struct TestCommand: Command {
      static var executed = false
      static var arguments: [String] {
        return []
      }
      @CommandArguments(short: "f", description: "Adds file path in which programs are searched for.")
      var filePath: [String]
      @CommandArguments(short: "l", description: "Adds file path in which libraries are searched for.")
      var libPaths: [String]
      @CommandArgument(short: "x", description: "Initial capacity of the heap")
      var heapSize: Int = 1234
      @CommandOption(short: "h", description: "Show description of usage and options of this tools.")
      var help: Bool
      @CommandFlags
      var flags: Flags
      mutating func run() {
        TestCommand.executed = true
      }
    }
    try TestCommand.main()
    XCTAssert(TestCommand.executed)
  }
  
  static let allTests = [
    ("testLongFlagNames2", testLongFlagNames2),
    ("testLongFlagNames", testLongFlagNames),
    ("testShortFlagNames", testShortFlagNames),
    ("testCommandFlags", testCommandFlags),
    ("testCommandFlagsFailure", testCommandFlagsFailure),
    ("testMoreCommandFlags", testMoreCommandFlags),
  ]
}
