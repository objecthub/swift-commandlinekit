//
//  ConvertibleFromString.swift
//  CommandLineKit
//
//  Created by Matthias Zenger on 26/03/2017.
//  Copyright © 2018 Google LLC
//
//  Use of this source code is governed by a BSD-style
//  license that can be found in the LICENSE file or at
//  https://developers.google.com/open-source/licenses/bsd
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
