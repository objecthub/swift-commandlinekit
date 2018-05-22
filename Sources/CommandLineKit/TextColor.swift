//
//  TextColor.swift
//  CommandLineKit
//
//  Created by Matthias Zenger on 07/04/2018.
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


public enum TextColor: Hashable {
  case black
  case maroon
  case green
  case olive
  case navy
  case purple
  case teal
  case silver
  case `default`
  case grey
  case red
  case lime
  case yellow
  case blue
  case fuchsia
  case aqua
  case white
  case extended(UInt8)
  
  public init?(colorCode: UInt8, fullColorSupport all256: Bool = false) {
    if all256 {
      self = .extended(colorCode)
    } else {
      switch colorCode {
        case 30:
          self = .black
        case 31:
          self = .maroon
        case 32:
          self = .green
        case 33:
          self = .olive
        case 34:
          self = .navy
        case 35:
          self = .purple
        case 36:
          self = .teal
        case 37:
          self = .silver
        case 39:
          self = .default
        case 90:
          self = .grey
        case 91:
          self = .red
        case 92:
          self = .lime
        case 93:
          self = .yellow
        case 94:
          self = .blue
        case 95:
          self = .fuchsia
        case 96:
          self = .aqua
        case 97:
          self = .white
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
      let color: TextColor?
      if code < 8 {
        color = TextColor(colorCode: code + 30)
      } else if code < 16 {
        color = TextColor(colorCode: code + 90)
      } else {
        color = nil
      }
      self = color ?? .default
    }
  }
  
  public var code: UInt8 {
    switch self {
      case .black:
        return 30
      case .maroon:
        return 31
      case .green:
        return 32
      case .olive:
        return 33
      case .navy:
        return 34
      case .purple:
        return 35
      case .teal:
        return 36
      case .silver:
        return 37
      case .default:
        return 39
      case .grey:
        return 90
      case .red:
        return 91
      case .lime:
        return 92
      case .yellow:
        return 93
      case .blue:
        return 94
      case .fuchsia:
        return 95
      case .aqua:
        return 96
      case .white:
        return 97
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
    return TextProperties(textColor: self)
  }
}
