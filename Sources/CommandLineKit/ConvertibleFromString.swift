//
//  ConvertibleFromString.swift
//  CommandLineKit
//
//  Created by Matthias Zenger on 26/03/2017.
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

import Foundation

///
/// Classes and structs implementing protocol `ConvertibleFromString` come with a default
/// initializer which initializes the object/struct by parsing a string.
///
public protocol ConvertibleFromString {
  init?(fromString: String)
}

extension ConvertibleFromString {
  public static func from(string str: String) -> Self? {
    return Self.init(fromString: str)
  }
}

extension String: ConvertibleFromString {
  public init?(fromString other: String) {
    self.init(other)
  }
}

extension Int: ConvertibleFromString {
  public init?(fromString str: String) {
    self.init(str)
  }
}

extension Int64: ConvertibleFromString {
  public init?(fromString str: String) {
    self.init(str)
  }
}

extension UInt: ConvertibleFromString {
  public init?(fromString str: String) {
    self.init(str)
  }
}

extension UInt64: ConvertibleFromString {
  public init?(fromString str: String) {
    self.init(str)
  }
}

extension Float: ConvertibleFromString {
  public init?(fromString str: String) {
    self.init(str)
  }
}

extension Double: ConvertibleFromString {
  public init?(fromString str: String) {
    self.init(str)
  }
}

extension Bool: ConvertibleFromString {
  public init?(fromString str: String) {
    switch str.lowercased() {
      case "true", "t", "yes", "y":
        self.init(true)
      case "false", "f", "no", "n":
        self.init(false)
      default:
        return nil
    }
  }
}

extension RawRepresentable where RawValue: ConvertibleFromString {
  public init?(fromString str: String) {
    guard let value = RawValue.from(string: str) else {
      return nil
    }
    self.init(rawValue: value)
  }
  
  public static func from(string str: String) -> Self? {
    return Self.init(fromString: str)
  }
}
