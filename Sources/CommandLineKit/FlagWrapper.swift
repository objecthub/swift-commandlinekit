//
//  FlagWrapper.swift
//  CommandLineKit
//
//  Created by Matthias Zenger on 20/08/2023.
//  Copyright © 2023 Matthias Zenger. All rights reserved.
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
/// Protocol implemented by all flag wrappers
///
public protocol FlagWrapper {
  func register(as: String?, with: Flags)
}

/// Base class for all flag wrappers
public class CommandFlag<Value, Flag> {
  
  public enum State<V, F> {
    case config(shortName: Character?, longName: String?, description: String, value: V)
    case flag(F)
  }
  
  public var state: State<Value, Flag>
  
  public var projectedValue: Flag {
    guard case .flag(let flag) = self.state else {
      preconditionFailure("accessing flags accessor before initialization")
    }
    return flag
  }
  
  public init(short: Character? = nil,
              long: String? = nil,
              description: String? = nil,
              value: Value) {
    self.state = .config(shortName: short,
                         longName: long,
                         description: description ?? "undocumented",
                         value: value)
  }
}

/// Inject the flags object into a command with the `@CommandFlags` property wrapper.
@propertyWrapper
public class CommandFlags: FlagWrapper {
  private var flags: Flags?
  
  public var wrappedValue: Flags {
    get {
      guard let flags = self.flags else {
        preconditionFailure("accessing flags accessor before initialization")
      }
      return flags
    }
  }
  
  public init() {
    self.flags = nil
  }
  
  public func register(as: String?, with flags: Flags) {
    self.flags = flags
  }
}

/// Declare an option flag
@propertyWrapper
public class CommandOption: CommandFlag<Bool, Option>, FlagWrapper {
  
  public var wrappedValue: Bool {
    get {
      guard case .flag(let flag) = self.state else {
        preconditionFailure("accessing flags accessor before initialization")
      }
      return flag.wasSet
    }
  }
  
  public init(short: Character? = nil,
              long: String? = nil,
              description: String? = nil) {
    super.init(short: short, long: long, description: description, value: false)
  }
  
  public func register(as optName: String?, with flags: Flags) {
    guard case .config(let short, let long, let descr, _) = self.state else {
      preconditionFailure("initializing flag twice")
    }
    var longName: String? = long
    if short == nil && long == nil {
      longName = optName
    }
    let flag = flags.option(short, longName, description: descr)
    self.state = .flag(flag)
  }
}

/// Declare an argument flag
@propertyWrapper
public class CommandArgument<Value>: CommandFlag<Value, SingletonArgument<Value>>, FlagWrapper
                                     where Value: ConvertibleFromString {
  
  public var wrappedValue: Value {
    get {
      guard case .flag(let flag) = self.state else {
        preconditionFailure("accessing flags accessor before initialization")
      }
      return flag.value!
    }
  }
  
  public init<T>(short: Character? = nil,
                 long: String? = nil,
                 description: String? = nil) where Value == Optional<T> {
    super.init(short: short, long: long, description: description, value: nil)
  }
  
  public init(wrappedValue: Value,
              short: Character? = nil,
              long: String? = nil,
              description: String? = nil) {
    super.init(short: short, long: long, description: description, value: wrappedValue)
  }
  
  public func register(as argName: String?, with flags: Flags) {
    guard case .config(let short, let long, let descr, let value) = self.state else {
      preconditionFailure("initializing flag twice")
    }
    var longName: String? = long
    if short == nil && long == nil {
      longName = argName
    }
    let flag = SingletonArgument(shortName: short,
                                 longName: longName,
                                 description: descr,
                                 value: value)
    flags.register(flag)
    self.state = .flag(flag)
  }
}

/// Declare a repeated argument flag
@propertyWrapper
public class CommandArguments<Value>: CommandFlag<Int, RepeatedArgument<Value>>, FlagWrapper
                                      where Value: ConvertibleFromString {
  
  public var wrappedValue: [Value] {
    get {
      guard case .flag(let flag) = self.state else {
        preconditionFailure("accessing flags accessor before initialization")
      }
      return flag.value
    }
  }
  
  public init(short: Character? = nil,
              long: String? = nil,
              description: String? = nil,
              maxCount: Int = Int.max) {
    super.init(short: short, long: long, description: description, value: maxCount)
  }
  
  public func register(as argName: String?, with flags: Flags) {
    guard case .config(let short, let long, let descr, let value) = self.state else {
      preconditionFailure("initializing flag twice")
    }
    var longName: String? = long
    if short == nil && long == nil {
      longName = argName
    }
    let flag = RepeatedArgument<Value>(shortName: short,
                                       longName: longName,
                                       description: descr,
                                       maxCount: value)
    flags.register(flag)
    self.state = .flag(flag)
  }
}

/// Inject the remaining/unparsed parameters into a command with the `@CommandParameters`
/// property wrapper.
@propertyWrapper
public class CommandParameters: FlagWrapper {
  private var flags: Flags?
  
  public var wrappedValue: [String] {
    get {
      guard let flags = self.flags else {
        preconditionFailure("accessing flags accessor before initialization")
      }
      return flags.parameters
    }
  }
  
  public init() {
    self.flags = nil
  }
  
  public func register(as: String?, with flags: Flags) {
    self.flags = flags
  }
}
