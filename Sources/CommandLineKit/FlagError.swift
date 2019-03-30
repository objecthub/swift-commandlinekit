//
//  FlagError.swift
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
