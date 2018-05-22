//
//  Flags.swift
//  CommandLineKit
//
//  Created by Matthias Zenger on 25/03/2017.
//  Copyright © 2018 Google LLC
//
//  Use of this source code is governed by a BSD-style
//  license that can be found in the LICENSE file or at
//  https://developers.google.com/open-source/licenses/bsd
//

import Foundation

///
/// Class `Flags` defines a builder for defining a set of supported command-line flags and
/// for extracting and parsing them from a given command-line. `Flags` objects are used in three
/// subsequent stages:
///    1. A new flags object is created for a command-line (represented as an array of strings),
///    2. The flags are defined via `register`, `option`, `argument`, and `arguments`, and
///    3. The flags are parsed by calling `parse`.
///
public class Flags {
  
  /// Terminator for command-line parsing. All following arguments are considered global
  /// parameters.
  internal static let terminator = "---"
  
  /// Prefix for long flag names (consisting of multiple characters)
  internal static let longNamePrefix = "--"
  
  /// Prefix for short flag names (consisting of a single character)
  internal static let shortNamePrefix = "-"
  
  /// The registered flags.
  private var descriptors: [Flag] = []
  
  /// Internal map from short name to flag.
  private var shortNameMap: [Character : Flag] = [:]
  
  /// Internal map from long name to flag.
  private var longNameMap: [String : Flag] = [:]
  
  /// The command-line arguments
  public let arguments: [String]
  
  /// Sequence of global parameters not associated with a flag
  public private(set) var parameters: [String] = []
  
  /// Initializes a flag set using the default command-line arguments.
  public init() {
    var args = CommandLine.arguments
    args.removeFirst()
    self.arguments = args
  }
  
  /// Initializes a flag set from the given command-line.
  public init(_ arguments: [String]) {
    self.arguments = arguments
  }
  
  /// Parses the command-line given the previously defined flags.
  public func parse() throws {
    var i = 0
    while i < self.arguments.count {
      let arg = self.arguments[i]
      i += 1
      if arg == Flags.terminator {
        while i < self.arguments.count {
          self.parameters.append(self.arguments[i])
          i += 1
        }
      } else if arg.hasPrefix(Flags.longNamePrefix) {
        let len = Flags.longNamePrefix.count
        // let longName = arg.substring(from: arg.index(arg.startIndex, offsetBy: len))
        let longName = String(arg[arg.index(arg.startIndex, offsetBy: len)...])
        guard let flag = self.longNameMap[longName] else {
          throw FlagError(.unknownFlag(arg))
        }
        i = try flag.parse(self.arguments, at: i)
      } else if arg.hasPrefix(Flags.shortNamePrefix) {
        let len = Flags.shortNamePrefix.count
        var index = arg.index(arg.startIndex, offsetBy: len)
        if index == arg.endIndex {
          self.parameters.append(arg)
        } else {
          while index < arg.endIndex {
            guard let flag = self.shortNameMap[arg[index]] else {
              throw FlagError(.unknownFlag(String(arg[index])))
            }
            index = arg.index(after: index)
            if index == arg.endIndex {
              i = try flag.parse(self.arguments, at: i)
            } else if flag.isOption {
              let j = try flag.parse(self.arguments, at: i)
              assert(i == j, "malformed option")
            } else {
              throw FlagError(.illegalFlagCombination(arg))
            }
          }
        }
      } else {
        self.parameters.append(arg)
      }
    }
  }
  
  /// Registers a new custom flag.
  public func register(_ flag: Flag) {
    if let shortName = flag.shortName {
      assert(self.shortNameMap[shortName] == nil,
             "ambiguous definition of flag \(Flags.shortNamePrefix)\(shortName)")
      self.shortNameMap[shortName] = flag
    }
    if let longName = flag.longName {
      assert(self.longNameMap[longName] == nil,
             "ambiguous definition of flag \(Flags.shortNamePrefix)\(longName)")
      self.longNameMap[longName] = flag
    }
    self.descriptors.append(flag)
  }
  
  /// Registers a new option for the given short flag name, long flag name, and description.
  public func option(_ shortName: Character?,
                     _ longName: String? = nil,
                     description: String) -> Option {
    let flag = Option(shortName: shortName,
                      longName: longName,
                      description: description)
    self.register(flag)
    return flag
  }
  
  /// Registers a new argument of type `T` for the given short flag name, long flag name, and
  /// description. `repeated` needs to be set to true if the argument is allowed to have multiple
  /// parameters. Function `set` is used to persist the parsed values of type `T`.
  public func argument<T: ConvertibleFromString>(_ shortName: Character?,
                                                 _ longName: String? = nil,
                                                 description: String,
                                                 repeated: Bool = false,
                                                 set: @escaping (T) -> Void) -> Argument {
    let flag = Argument(shortName: shortName,
                        longName: longName,
                        description: description,
                        repeated: repeated,
                        set: set)
    self.register(flag)
    return flag
  }
  
  /// Registers a new singleton argument of type `T` for the given short flag name, long flag
  /// name, and description. `value` defines an optional default parameter value.
  public func argument<T: ConvertibleFromString>(_ shortName: Character?,
                                                 _ longName: String? = nil,
                                                 description: String,
                                                 value: T? = nil) -> SingletonArgument<T> {
    let flag = SingletonArgument<T>(shortName: shortName,
                                    longName: longName,
                                    description: description,
                                    value: value)
    self.register(flag)
    return flag
  }
  
  /// Registers a new repeated argument of type `T` for the given short flag name, long flag
  /// name, and description. `maxCount` determines how many parameters are accepted at most.
  public func arguments<T: ConvertibleFromString>(_ shortName: Character?,
                                                  _ longName: String? = nil,
                                                  description: String,
                                                  maxCount: Int = Int.max) -> RepeatedArgument<T> {
    let flag = RepeatedArgument<T>(shortName: shortName,
                                   longName: longName,
                                   description: description,
                                   maxCount: maxCount)
    self.register(flag)
    return flag
  }
}

///
/// This extension defines a few convenience methods for registering arguments of type `String`,
/// `Int`, `Double`, and enumerations whose raw type implements the `ConvertibleFromString`
/// protocol.
///
extension Flags {
  
  public func string(_ shortName: Character?,
                     _ longName: String? = nil,
                     description: String,
                     value: String? = nil) -> SingletonArgument<String> {
    return self.argument(shortName, longName, description: description, value: value)
  }
  
  public func `enum`<T: RawRepresentable>(_ shortName: Character?,
                                          _ longName: String? = nil,
                                          description: String,
                                          value: T? = nil) -> SingletonArgument<T>
                    where T.RawValue: ConvertibleFromString {
    let flag = SingletonArgument<T>(shortName: shortName,
                                    longName: longName,
                                    description: description,
                                    value: value,
                                    parse: T.from)
    self.register(flag)
    return flag
  }
  
  public func int(_ shortName: Character?,
                  _ longName: String? = nil,
                  description: String,
                  value: Int? = nil) -> SingletonArgument<Int> {
    return self.argument(shortName, longName, description: description, value: value)
  }
  
  public func double(_ shortName: Character?,
                     _ longName: String? = nil,
                     description: String,
                     value: Double? = nil) -> SingletonArgument<Double> {
    return self.argument(shortName, longName, description: description, value: value)
  }
  
  public func strings(_ shortName: Character?,
                      _ longName: String? = nil,
                      description: String,
                      maxCount: Int = Int.max) -> RepeatedArgument<String> {
    return self.arguments(shortName, longName, description: description, maxCount: maxCount)
  }
  
  public func enums<T: RawRepresentable>(_ shortName: Character?,
                                         _ longName: String? = nil,
                                         description: String,
                                         maxCount: Int = Int.max) -> RepeatedArgument<T>
                   where T.RawValue: ConvertibleFromString {
      let flag = RepeatedArgument<T>(shortName: shortName,
                                     longName: longName,
                                     description: description,
                                     maxCount: maxCount,
                                     parse: T.from)
      self.register(flag)
      return flag
  }
  
  public func ints(_ shortName: Character?,
                   _ longName: String? = nil,
                   description: String,
                   maxCount: Int = Int.max) -> RepeatedArgument<Int> {
    return self.arguments(shortName, longName, description: description, maxCount: maxCount)
  }
  
  public func doubles(_ shortName: Character?,
                      _ longName: String? = nil,
                      description: String,
                      maxCount: Int = Int.max) -> RepeatedArgument<Double> {
    return self.arguments(shortName, longName, description: description, maxCount: maxCount)
  }
}
