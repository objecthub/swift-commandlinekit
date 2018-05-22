//
//  BackgroundColor.swift
//  CommandLineKit
//
//  Created by Matthias Zenger on 18/04/2018.
//  Copyright © 2018 Google LLC
//
//  Use of this source code is governed by a BSD-style
//  license that can be found in the LICENSE file or at
//  https://developers.google.com/open-source/licenses/bsd
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
