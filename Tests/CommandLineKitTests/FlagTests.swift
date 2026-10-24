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
  
  /// By default, repeated arguments are greedy: they consume all arguments up to the next flag.
  func testGreedyRepeatedArguments() throws {
    let flags = Flags(arguments: ["-r", "a", "b", "prog.scm", "-q", "-i", "x", "y", "---", "z"])
    let roots = flags.strings("r", "root", description: "roots")
    let imports = flags.strings("i", "import", description: "imports")
    let quiet = flags.option("q", description: "quiet")
    try flags.parse()
    XCTAssertTrue(roots.greedy)
    XCTAssertEqual(roots.value, ["a", "b", "prog.scm"])
    XCTAssertEqual(imports.value, ["x", "y"])
    XCTAssertTrue(quiet.wasSet)
    XCTAssertEqual(flags.parameters, ["z"])
  }

  /// A greedy repeated argument accepts the absence of parameters.
  func testGreedyRepeatedArgumentsWithoutValues() throws {
    let flags = Flags(arguments: ["-r", "-q"])
    let roots = flags.strings("r", description: "roots")
    let quiet = flags.option("q", description: "quiet")
    try flags.parse()
    XCTAssertEqual(roots.value, [])
    XCTAssertTrue(quiet.wasSet)
  }

  /// Non-greedy repeated arguments take one parameter per occurrence of the flag. Parameters
  /// following the flag, such as the name of a program, are not consumed by the flag.
  func testNonGreedyRepeatedArguments() throws {
    let flags = Flags(arguments: ["-r", "a", "-r", "b", "--root", "c", "prog.scm", "arg"])
    let roots = flags.strings("r", "root", description: "roots", greedy: false)
    try flags.parse()
    XCTAssertFalse(roots.greedy)
    XCTAssertTrue(roots.wasSet)
    XCTAssertEqual(roots.value, ["a", "b", "c"])
    XCTAssertEqual(flags.parameters, ["prog.scm", "arg"])
  }

  /// Non-greedy repeated arguments can be mixed with other flags and with the terminator.
  func testNonGreedyRepeatedArgumentsWithOtherFlags() throws {
    let flags = Flags(arguments: ["-r", "a", "-q", "-i", "scheme base", "-r", "b", "-d", "dir",
                                  "prog.scm", "-f", "file", "---", "-r", "x"])
    let roots = flags.strings("r", description: "roots", greedy: false)
    let imports = flags.strings("i", description: "imports", greedy: false)
    let files = flags.strings("f", description: "files")
    let dir = flags.string("d", description: "dir")
    let quiet = flags.option("q", description: "quiet")
    try flags.parse()
    XCTAssertEqual(roots.value, ["a", "b"])
    XCTAssertEqual(imports.value, ["scheme base"])
    XCTAssertEqual(files.value, ["file"])
    XCTAssertEqual(dir.value, "dir")
    XCTAssertTrue(quiet.wasSet)
    XCTAssertEqual(flags.parameters, ["prog.scm", "-r", "x"])
  }

  /// Every occurrence of a non-greedy repeated argument needs a parameter.
  func testNonGreedyRepeatedArgumentsRequireValue() throws {
    for arguments in [["-r"], ["-r", "-q"], ["-r", "a", "-r"], ["-r", "--quiet"], ["-r", "---", "p"]] {
      let flags = Flags(arguments: arguments)
      _ = flags.strings("r", description: "roots", greedy: false)
      _ = flags.option("q", "quiet", description: "quiet")
      XCTAssertThrowsError(try flags.parse(), "\(arguments)") { error in
        guard let flagError = error as? FlagError, case .missingValue = flagError.kind else {
          return XCTFail("unexpected error \(error) for \(arguments)")
        }
      }
    }
  }

  /// Negative numbers are parameters, also for non-greedy repeated arguments, and `maxCount`
  /// limits the total number of parameters.
  func testNonGreedyRepeatedNumbers() throws {
    let flags = Flags(arguments: ["-n", "-3", "-n", "4", "5"])
    let numbers = flags.ints("n", description: "numbers", maxCount: 2, greedy: false)
    try flags.parse()
    XCTAssertEqual(numbers.value, [-3, 4])
    XCTAssertEqual(flags.parameters, ["5"])
    let limited = Flags(arguments: ["-n", "1", "-n", "2", "-n", "3"])
    _ = limited.ints("n", description: "numbers", maxCount: 2, greedy: false)
    XCTAssertThrowsError(try limited.parse())
  }

  /// The usage description shows that greedy arguments take several parameters.
  func testRepeatedArgumentUsage() throws {
    let flags = Flags(arguments: [])
    _ = flags.strings("g", "greedy", description: "greedy argument")
    _ = flags.strings("n", "single", description: "non-greedy argument", greedy: false)
    _ = flags.strings("c", "custom", paramIdent: "<dir>", description: "custom", greedy: false)
    let usage = flags.usageDescription()
    XCTAssertTrue(usage.contains("-g, --greedy <value> ..."))
    XCTAssertTrue(usage.contains("-n, --single <value>\n"))
    XCTAssertTrue(usage.contains("-c, --custom <dir>\n"))
  }

  /// Terminator `---` ends the parsing of flags: all arguments following it are parameters.
  func testTerminator() throws {
    let flags = Flags(arguments: ["-r", "a", "b", "---", "prog.scm", "-q", "--", "---", "c"])
    let roots = flags.strings("r", "root", description: "roots")
    let quiet = flags.option("q", description: "quiet")
    try flags.parse()
    XCTAssertEqual(roots.value, ["a", "b"])
    XCTAssertFalse(quiet.wasSet)
    XCTAssertEqual(flags.parameters, ["prog.scm", "-q", "--", "---", "c"])
  }

  /// Terminator `--` ends the parameters of a greedy repeated argument. In contrast to `---`,
  /// the remaining arguments are parsed as usual. This makes it possible to use multiple
  /// greedy repeated arguments in front of the parameters.
  func testArgumentTerminator() throws {
    let flags = Flags(arguments: ["-f", "a", "b", "--", "-l", "c", "d", "--", "-q", "prog.scm",
                                  "x", "---", "-q", "--"])
    let files = flags.strings("f", description: "files")
    let libs = flags.strings("l", description: "libs")
    let quiet = flags.option("q", description: "quiet")
    try flags.parse()
    XCTAssertEqual(files.value, ["a", "b"])
    XCTAssertEqual(libs.value, ["c", "d"])
    XCTAssertTrue(quiet.wasSet)
    XCTAssertEqual(flags.parameters, ["prog.scm", "x", "-q", "--"])
    // Arguments with `--` between flags
    let more = Flags(arguments: ["--root", "a", "--", "--root", "b", "c", "--", "prog"])
    let roots = more.strings("r", "root", description: "roots")
    try more.parse()
    XCTAssertEqual(roots.value, ["a", "b", "c"])
    XCTAssertEqual(more.parameters, ["prog"])
    // Greedy repeated arguments accept the absence of parameters
    let empty = Flags(arguments: ["-f", "--", "prog"])
    let emptyFiles = empty.strings("f", description: "files")
    try empty.parse()
    XCTAssertEqual(emptyFiles.value, [])
    XCTAssertEqual(empty.parameters, ["prog"])
  }

  /// Terminator `--` has no effect on other flags. It is ignored if it does not follow a
  /// repeated argument, and it is never a parameter value.
  func testArgumentTerminatorElsewhere() throws {
    let flags = Flags(arguments: ["-q", "--", "-r", "a", "--", "prog", "--", "x"])
    let roots = flags.strings("r", description: "roots", greedy: false)
    let quiet = flags.option("q", description: "quiet")
    try flags.parse()
    XCTAssertTrue(quiet.wasSet)
    XCTAssertEqual(roots.value, ["a"])
    XCTAssertEqual(flags.parameters, ["prog", "x"])
    // Flags that require a parameter do not consume `--` as a parameter
    for arguments in [["-s", "--", "x"], ["-r", "--", "x"]] {
      let failing = Flags(arguments: arguments)
      _ = failing.string("s", description: "string")
      _ = failing.strings("r", description: "roots", greedy: false)
      XCTAssertThrowsError(try failing.parse(), "\(arguments)")
    }
  }

  func testNonGreedyCommandArguments() throws {
    struct TestCommand: Command {
      static var executed = false
      static var roots: [String] = []
      static var libs: [String] = []
      static var params: [String] = []
      static var arguments: [String] {
        return ["-r", "a", "-r", "b", "-l", "x", "y", "prog.scm", "arg"]
      }
      @CommandArguments(short: "r", description: "roots", greedy: false) var roots: [String]
      @CommandArguments(short: "l", description: "libs") var libs: [String]
      @CommandParameters var params: [String]
      mutating func run() {
        TestCommand.executed = true
        TestCommand.roots = self.roots
        TestCommand.libs = self.libs
        TestCommand.params = self.params
      }
    }
    try TestCommand.main()
    XCTAssert(TestCommand.executed)
    XCTAssertEqual(TestCommand.roots, ["a", "b"])
    XCTAssertEqual(TestCommand.libs, ["x", "y", "prog.scm", "arg"])
    XCTAssertEqual(TestCommand.params, [])
  }

  static let allTests = [
    ("testLongFlagNames2", testLongFlagNames2),
    ("testLongFlagNames", testLongFlagNames),
    ("testShortFlagNames", testShortFlagNames),
    ("testCommandFlags", testCommandFlags),
    ("testCommandFlagsFailure", testCommandFlagsFailure),
    ("testMoreCommandFlags", testMoreCommandFlags),
    ("testGreedyRepeatedArguments", testGreedyRepeatedArguments),
    ("testGreedyRepeatedArgumentsWithoutValues", testGreedyRepeatedArgumentsWithoutValues),
    ("testNonGreedyRepeatedArguments", testNonGreedyRepeatedArguments),
    ("testNonGreedyRepeatedArgumentsWithOtherFlags",
     testNonGreedyRepeatedArgumentsWithOtherFlags),
    ("testNonGreedyRepeatedArgumentsRequireValue", testNonGreedyRepeatedArgumentsRequireValue),
    ("testNonGreedyRepeatedNumbers", testNonGreedyRepeatedNumbers),
    ("testRepeatedArgumentUsage", testRepeatedArgumentUsage),
    ("testTerminator", testTerminator),
    ("testArgumentTerminator", testArgumentTerminator),
    ("testArgumentTerminatorElsewhere", testArgumentTerminatorElsewhere),
    ("testNonGreedyCommandArguments", testNonGreedyCommandArguments),
  ]
}
