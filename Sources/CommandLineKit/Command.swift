//
//  Command.swift
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
/// The command protocol implements an API for command-line tools. A `Flags` object
/// gets automatically instantiated and flags, declared with flag property wrappers,
/// are automatically registered with the `Flags` object. If flag parsing results in
/// an error, the `fail(with: String)` method is called. Otherwise, `run()` gets
/// executed.
/// 
public protocol Command {
  static var name: String { get }
  static var arguments: [String] { get }
  init()
  mutating func run() throws
  mutating func fail(with: String) throws
}

extension Command {
  
  public mutating func fail(with reason: String) {
    print(reason)
    exit(1)
  }
  
  public static var name: String {
    if let toolPath = CommandLine.arguments.first {
      return URL(fileURLWithPath: toolPath).lastPathComponent
    } else {
      let str = String(describing: self)
      if let i = str.firstIndex(of: "("), i > str.startIndex, i < str.endIndex {
        return String(str[str.startIndex..<i])
      } else {
        return str
      }
    }
  }
  
  public static var arguments: [String] {
    var args = CommandLine.arguments
    args.removeFirst()
    return args
  }
  
  public static func newFlags() -> Flags {
    return Flags(toolName: Self.name, arguments: Self.arguments)
  }
  
  public static func argumentNameConverter() -> ArgumentNameConverter {
    return ArgumentNameConverter(Self.argumentNamingStrategy())
  }
  
  public static func argumentNamingStrategy() -> ArgumentNameConverter.Strategy {
    return .lowercase
  }
  
  public static func main() throws {
    var command = Self()
    let flags = Self.newFlags()
    let converter = Self.argumentNameConverter()
    let children = Mirror(reflecting: command).children
    for child in children {
      if let wrapper = child.value as? FlagWrapper {
        if let label = child.label {
          if label.hasPrefix("_") {
            wrapper.register(as: converter.convert(String(label.dropFirst())), with: flags)
          } else {
            wrapper.register(as: converter.convert(label), with: flags)
          }
        } else {
          wrapper.register(as: nil, with: flags)
        }
      }
    }
    if let reason = flags.parsingFailure() {
      try command.fail(with: reason)
    } else {
      try command.run()
    }
  }
}

public class ArgumentNameConverter {
  
  public enum Strategy {
    case camelcase
    case lowercase
    case separate(Character)
  }
  
  public let strategy: Strategy
  public let prefix: String
  
  public init(_ strategy: Strategy = .lowercase, prefix: String = "") {
    self.strategy = strategy
    self.prefix = prefix
  }
  
  public func convert(_ name: String) -> String {
    guard !name.isEmpty else {
      return ""
    }
    switch self.strategy {
      case .camelcase:
        if prefix.isEmpty {
          return name
        } else {
          return prefix + name.prefix(1).capitalized + name.dropFirst()
        }
      case .lowercase:
        return (prefix + name).lowercased()
      case .separate(let separator):
        var index = name.startIndex
        var separate = true
        var res = ""
        while index < name.endIndex {
          let character = name[index]
          if character.isUppercase {
            if separate && !res.isEmpty {
              res.append(separator)
            }
            let next = name.index(after: index)
            separate = next < name.endIndex &&
                       name[next].isUppercase &&
                       name.index(after: next) < name.endIndex &&
                       name[name.index(after: next)].isLowercase
          } else {
            separate = character != separator
          }
          res += character.lowercased()
          index = name.index(after: index)
        }
        return res
    }
  }
}
