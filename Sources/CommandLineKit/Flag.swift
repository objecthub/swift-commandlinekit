//
//  Flag.swift
//  CommandLineKit
//
//  Created by Matthias Zenger on 25/03/2017.
//  Copyright © 2018-2019 Google LLC
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

///
/// A `Flag` object describes a command-line flag in terms of a short name, a long name, and
/// a description. A short name is a character excluding '-', '=', ' ', '0', '1', '2', '3', '4',
/// '5', '6', '7', '8', '9'. A long name is a non-empty string which does not contain whitespace
/// and '=' characters. Also a single dash is not supported as a long name.
///
/// There are two different types of flags: options and arguments. An option is a boolean flag:
/// it is either set or not set. An argument is a flag which comes with at least one argument.
/// Method `isOption` can be used to distinguish between options and arguments.
///
public class Flag {
  
  /// The short name of the flag.
  public let shortName: Character?
  
  /// The long name of the flag.
  public let longName: String?
  
  /// The description of the flag.
  public let helpDescription: String
  
  /// Is set to true if the flag was set on the command-line.
  public fileprivate(set) var wasSet: Bool
  
  /// Initializes a flag
  fileprivate init(shortName: Character?, longName: String?, description: String) {
    assert(shortName != nil || longName != nil, "declared flag without short and long name")
    if let name = shortName {
      assert(name != "0" && name != "1" && name != "2" && name != "3" && name != "4" &&
             name != "5" && name != "6" && name != "7" && name != "8" && name != "9" &&
             name != "-" && name != "=" && name != " ",
             "short flag name consists of illegal character")
    }
    if let name = longName {
      assert(name.count != 0, "long flag name is empty for flag -\(shortName ?? "?")")
      assert(name.contains { $0 == " " || $0 == "=" } == false,
             "long flag name --\(name) contains illegal characters")
      assert(name != "-", "long flag name --\(name) is a dash")
    }
    self.shortName = shortName
    self.longName = longName
    self.helpDescription = description
    self.wasSet = false
  }
  
  /// Returns true if this flag descriptor represents an option; i.e. a flag without argument.
  public var isOption: Bool {
    return false
  }
  
  /// Parses the arguments of the flag starting `index` in argument array `args`.
  public func parse(_ args: [String], at index: Int) throws -> Int {
    self.wasSet = true
    return index
  }
}

///
/// An `Option` is a flag that is either present or absent. If an option is present, the field
/// `wasSet` is set to true. It is also possible to register a callback which gets invoked when
/// the option was found during command-line parsing.
///
public final class Option: Flag {
  private let notify: () throws -> Void
  
  /// Initializes an option with a parsing callback.
  public init(shortName: Character?,
              longName: String?,
              description: String,
              notify: @escaping () throws -> Void) {
    self.notify = notify
    super.init(shortName: shortName, longName: longName, description: description)
  }
  
  /// Initializes an option without parsing callback.
  public override convenience init(shortName: Character?,
                                   longName: String?,
                                   description: String) {
    self.init(shortName: shortName, longName: longName, description: description, notify: {})
  }
  
  /// Returns true
  public override var isOption: Bool {
    return true
  }
  
  /// Parses an option.
  public override func parse(_ args: [String], at index: Int) throws -> Int {
    try self.notify()
    self.wasSet = true
    return index
  }
}

///
/// An `Argument` is a flag with parameters. Flags which allow multiple parameters need to
/// get initialized such that `repeated` is set to true. For being able to handle
/// arguments, the argument object needs to be provided a `handler` function which is
/// responsible for parsing the string parameters and persisting the result.
///
public class Argument: Flag {
  
  /// Is this argument repeated?
  public let repeated: Bool
  
  /// Handler for parsing and persisting argument values.
  internal private(set) var handler: (String) throws -> Void
  
  /// A readable parameter name, used for documentation purposes.
  public let paramIdent: String
  
  /// Initializes an argument from the given short name, long name, and description. `repeated`
  /// needs to be set to true if the argument accepts multiple parameters. `handler` is used
  /// for parsing and persisting parameters.
  public init(shortName: Character?,
              longName: String?,
              paramIdent: String? = nil,
              description: String,
              repeated: Bool = false,
              handler: @escaping (String) throws -> Void) {
    self.repeated = repeated
    self.handler = handler
    self.paramIdent = paramIdent == nil ? (repeated ? "<value> ..." : "<value>") : paramIdent!
    super.init(shortName: shortName, longName: longName, description: description)
  }
  
  /// Initializes an argument of type `T` from the given short name, long name, and description.
  /// `repeated` needs to be set to true if the argument accepts multiple parameters. `parse` is
  /// used to parse the string parameter into a value of type `T`. `set` persists values of
  /// type `T`.
  public convenience init<T>(shortName: Character?,
                             longName: String?,
                             paramIdent: String? = nil,
                             description: String,
                             repeated: Bool = false,
                             parse: @escaping (String) -> T?,
                             set: @escaping (T) throws -> Void) {
    self.init(shortName: shortName,
              longName: longName,
              paramIdent: paramIdent,
              description: description,
              repeated: repeated,
              handler: { x in })
    self.setHandler(parse: parse, set: set)
  }
  
  /// Initializes an argument of type `T` from the given short name, long name, and description.
  /// `repeated` needs to be set to true if the argument accepts multiple parameters. This
  /// initializer handles subtypes of `ConvertibleFromString` which come with a default parsing
  /// method. `set` persists values of type `T`.
  public convenience init<T: ConvertibleFromString>(shortName: Character?,
                                                    longName: String?,
                                                    paramIdent: String? = nil,
                                                    description: String,
                                                    repeated: Bool = false,
                                                    set: @escaping (T) throws -> Void) {
    self.init(shortName: shortName,
              longName: longName,
              paramIdent: paramIdent,
              description: description,
              repeated: repeated,
              handler: { x in })
    self.setHandler(parse: T.from, set: set)
  }
  
  /// Initializes an argument of type `T` from the given short name, long name, and description.
  /// `repeated` needs to be set to true if the argument accepts multiple parameters. This
  /// initializer handles subtypes of `ConvertibleFromString` which come with a default parsing
  /// method. `set` persists values of type `T`.
  public convenience init<T: RawRepresentable>(shortName: Character?,
                                               longName: String?,
                                               paramIdent: String? = nil,
                                               description: String,
                                               repeated: Bool = false,
                                               set: @escaping (T) throws -> Void)
                         where T.RawValue: ConvertibleFromString {
    self.init(shortName: shortName,
              longName: longName,
              paramIdent: paramIdent,
              description: description,
              repeated: repeated,
              handler: { x in })
    self.setHandler(parse: T.from, set: set)
  }
  
  /// Used internally to construct a handler from a `parse` and `set` function.
  fileprivate func setHandler<T>(parse: @escaping (String) -> T?,
                                 set: @escaping (T) throws -> Void) {
    self.handler = { [unowned self] arg in
      guard let value = parse(arg) else {
        throw FlagError(.malformedValue(arg), self)
      }
      try set(value)
    }
  }
  
  /// Parses an option.
  public override func parse(_ args: [String], at index: Int) throws -> Int {
    var i = index
    while i < args.count {
      let arg = args[i]
      if arg == Flags.terminator || arg.hasPrefix(Flags.longNamePrefix) {
        guard self.repeated else {
          throw FlagError(.missingValue, self)
        }
        return i
      } else if arg.hasPrefix("-0") || arg.hasPrefix("-1") || arg.hasPrefix("-2") ||
                arg.hasPrefix("-3") || arg.hasPrefix("-4") || arg.hasPrefix("-5") ||
                arg.hasPrefix("-6") || arg.hasPrefix("-7") || arg.hasPrefix("-8") ||
                arg.hasPrefix("-9") {
        try self.handler(arg)
        self.wasSet = true
        i += 1
        guard self.repeated else {
          return i
        }
      } else if arg.hasPrefix("-") {
        guard self.repeated else {
          throw FlagError(.missingValue, self)
        }
        return i
      } else {
        try self.handler(arg)
        self.wasSet = true
        i += 1
        guard self.repeated else {
          return i
        }
      }
    }
    guard self.repeated else {
      throw FlagError(.missingValue, self)
    }
    return i
  }
}

///
/// A `SingletonArgument` encapsulates a single, optional parameter value of type `T`. This
/// class is most commonly used in command-line applications for handling arguments with a
/// single parameter where the parameter extracted from the command-line is stored in the
/// flag object itself.
///
public final class SingletonArgument<T>: Argument {
  public var value: T?
  
  /// Initializes a singleton argument from the given short name, long name, and description.
  /// `value` is a default value for the parameter. `parse` is used to parse strings into
  /// values of type `T`.
  public init(shortName: Character?,
              longName: String?,
              paramIdent: String? = nil,
              description: String,
              value: T? = nil,
              parse: @escaping (String) -> T?) {
    self.value = value
    super.init(shortName: shortName,
               longName: longName,
               paramIdent: paramIdent,
               description: description,
               handler: { x in })
    self.setHandler(parse: parse, set: { [unowned self] value in self.value = value })
  }
}

extension SingletonArgument where T: ConvertibleFromString {
  
  /// Initializes a singleton argument from the given short name, long name, and description.
  /// `value` is a default value for the parameter. The default parsing function is used.
  public convenience init(shortName: Character?,
                          longName: String?,
                          paramIdent: String? = nil,
                          description: String,
                          value: T? = nil) {
    self.init(shortName: shortName,
              longName: longName,
              paramIdent: paramIdent,
              description: description,
              value: value,
              parse: T.from)
  }
}

///
/// A `RepeatedArgument` encapsulates a sequence of parameter values of type `T`. This
/// class is most commonly used in command-line applications for handling arguments with
/// potentially multiple parameter values where the parameters extracted from the command-line
/// are stored in the flag object itself.
///
public final class RepeatedArgument<T>: Argument {
  private let maxCount: Int
  public var value: [T]
  
  /// Initializes a repeated argument from the given short name, long name, and description.
  /// `maxCount` determines how many parameters are acceptable. `parse` is used to parse strings
  /// into values of type `T`.
  public init(shortName: Character?,
              longName: String?,
              paramIdent: String? = nil,
              description: String,
              maxCount: Int = Int.max,
              parse: @escaping (String) -> T?) {
    self.maxCount = maxCount
    self.value = []
    super.init(shortName: shortName,
               longName: longName,
               paramIdent: paramIdent,
               description: description,
               repeated: true,
               handler: { x in })
    self.setHandler(parse: parse, set: { [unowned self] value in
      guard self.value.count < self.maxCount else {
        throw FlagError(.tooManyValues(String(describing: self.value)), self)
      }
      self.value.append(value)
    })
  }
}

extension RepeatedArgument where T: ConvertibleFromString {
  
  /// Initializes a repeated argument from the given short name, long name, and description.
  /// `maxCount` determines how many parameters are acceptable. The default parsing function
  /// is used.
  public convenience init(shortName: Character?,
                          longName: String?,
                          paramIdent: String? = nil,
                          description: String,
                          maxCount: Int = Int.max) {
    self.init(shortName: shortName,
              longName: longName,
              paramIdent: paramIdent,
              description: description,
              maxCount: maxCount,
              parse: T.from)
  }
}

