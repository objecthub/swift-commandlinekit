//
//  TextStyle.swift
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

public enum TextStyle: UInt8, Hashable {
  case `default` = 0
  case bold = 1
  case dim = 2
  case italic = 3
  case underline = 4
  case blink = 5
  case swap = 7
  
  public var code: UInt8 {
    return self.rawValue
  }
  
  public var properties: TextProperties {
    return TextProperties(textStyles: [self])
  }
}
