//
//  BackgroundColor.swift
//  CommandLineKit
//
//  Created by Matthias Zenger on 18/04/2018.
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

public enum BackgroundColor: Hashable {
  case black
  case red
  case green
  case yellow
  case blue
  case magenta
  case cyan
  case white
  case `default`
  case extended(UInt8)
  
  public init?(colorCode: UInt8, fullColorSupport all256: Bool = false) {
    if all256 {
      self = .extended(colorCode)
    } else {
      switch colorCode {
        case 40:
          self = .black
        case 41:
          self = .red
        case 42:
          self = .green
        case 43:
          self = .yellow
        case 44:
          self = .blue
        case 45:
          self = .magenta
        case 46:
          self = .cyan
        case 47:
          self = .white
        case 49:
          self = .default
        default:
          return nil
      }
    }
  }
  
  public init(color: (UInt8, UInt8, UInt8), fullColorSupport all256: Bool = false) {
    let code = Terminal.closestColor(to: color, fullColorSupport: all256)
    if all256 {
      self = .extended(code)
    } else {
      let color: BackgroundColor? = code < 8 ? BackgroundColor(colorCode: code + 40) : nil
      self = color ?? .default
    }
  }
  
  public var code: UInt8 {
    switch self {
      case .black:
        return 40
      case .red:
        return 41
      case .green:
        return 42
      case .yellow:
        return 43
      case .blue:
        return 44
      case .magenta:
        return 45
      case .cyan:
        return 46
      case .white:
        return 47
      case .default:
        return 49
      case .extended(let c):
        return c
    }
  }
  
  public var isExtended: Bool {
    guard case .extended(_) = self else {
      return false
    }
    return true
  }
  
  public var properties: TextProperties {
    return TextProperties(backgroundColor: self)
  }
}
