//
//  FlagError.swift
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
/// Enum `FlagError` defines all the errors potentially returned when parsing command-line
/// arguments. Each flag error consists of a `kind` defining the type of the error as well
/// as an optional `flag` referring to the flag to which the error belongs.
///
public struct FlagError: Error {
  
  /// The description of the error.
  public enum Kind {
    case unknownFlag(String)
    case missingValue
    case malformedValue(String)
    case illegalFlagCombination(String)
    case tooManyValues(String)
  }
  
  /// The error kind.
  public let kind: Kind
  
  /// The flag to which the error belongs. If `flag` is set to nil, the error is related to
  /// parsing the command-line as a whole.
  public let flag: Flag?
  
  /// Initializes a new flag error from an error kind and a corresponding flag.
  public init(_ kind: Kind, _ flag: Flag? = nil) {
    self.kind = kind
    self.flag = flag
  }
}
