//
//  TextProperties.swift
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

///
/// A `TextProperties` struct bundles a text color, a background color and a text style
/// in one object. Text properties can be merged with the `with(:)` functions and applied to
/// a string with the `apply(to:)` function.
///
public struct TextProperties: Hashable {
  let textColor: TextColor?
  let backgroundColor: BackgroundColor?
  let textStyles: Set<TextStyle>
  
  public static let none = TextProperties()
  
  public init(textColor: TextColor? = nil,
              backgroundColor: BackgroundColor? = nil,
              textStyles: Set<TextStyle> = []) {
    self.textColor = textColor
    self.backgroundColor = backgroundColor
    self.textStyles = textStyles
  }
  
  public init(_ tcolor: TextColor? = nil,
              _ bgcolor: BackgroundColor? = nil,
              _ tstyles: TextStyle...) {
    self.textColor = tcolor
    self.textStyles = Set(tstyles)
    self.backgroundColor = bgcolor
  }
  
  public var isEmpty: Bool {
    return self.textColor == nil && self.backgroundColor == nil && self.textStyles.isEmpty
  }
  
  public func with(_ properties: TextProperties) -> TextProperties {
    var styles = self.textStyles
    for style in properties.textStyles {
      styles.insert(style)
    }
    return TextProperties(textColor: properties.textColor ?? self.textColor,
                          backgroundColor: properties.backgroundColor ?? self.backgroundColor,
                          textStyles: styles)
  }
  
  public func with(_ tcolor: TextColor) -> TextProperties {
    return TextProperties(textColor: tcolor,
                          backgroundColor: self.backgroundColor,
                          textStyles: self.textStyles)
  }
  
  public func with(_ bgcolor: BackgroundColor) -> TextProperties {
    return TextProperties(textColor: self.textColor,
                          backgroundColor: bgcolor,
                          textStyles: self.textStyles)
  }
  
  public func with(_ tstyle: TextStyle) -> TextProperties {
    var styles = self.textStyles
    styles.insert(tstyle)
    return TextProperties(textColor: self.textColor,
                          backgroundColor: self.backgroundColor,
                          textStyles: styles)
  }
  
  public func apply(to text: String) -> String {
    if self.isEmpty {
      return text
    }
    var codes: [UInt8] = []
    if let color = self.textColor {
      if color.isExtended {
        codes.append(38)
        codes.append(5)
      }
      codes.append(color.code)
    }
    if let backgroundColor = self.backgroundColor {
      if backgroundColor.isExtended {
        codes.append(48)
        codes.append(5)
      }
      codes.append(backgroundColor.code)
    }
    codes += self.textStyles.map { $0.code }
    return codes.isEmpty ?
      text :
      "\(AnsiCodes.CSI)\(codes.map{String($0)}.joined(separator: ";"))m\(text)\(AnsiCodes.CSI)0m"
  }
  
  public static func extract(from str: String) -> (TextProperties, String) {
    let (codes, res) = TextProperties.extractCodes(from: str)
    return (TextProperties.interpret(codes: codes), res)
  }
  
  private static func extractCodes(from string: String) -> ([UInt8], String) {
    var index = string.index(string.startIndex, offsetBy: AnsiCodes.CSI.count)
    var codesString = ""
    while string[index] != "m" {
      codesString.append(string[index])
      index = string.index(after: index)
    }
    let codes = codesString.split(separator: ";",
                                  omittingEmptySubsequences: false).compactMap { UInt8($0) }
    let startIndex = string.index(after: index)
    let endIndex = string.index(string.endIndex, offsetBy: -"\(AnsiCodes.CSI)0m".count)
    let text = String(string[startIndex..<endIndex])
    return (codes, text)
  }
  
  private static func interpret(codes: [UInt8]) -> TextProperties {
    var color: TextColor? = nil
    var backgroundColor: BackgroundColor? = nil
    var styles: Set<TextStyle> = []
    var i = 0
    while i < codes.count {
      if (i + 2) < codes.count {
        if codes[i] == 38 && codes[i + 1] == 5 {
          color = TextColor(colorCode: codes[i + 2], fullColorSupport: true)
          i += 2
          continue
        } else if codes[i] == 48 && codes[i + 1] == 5 {
          backgroundColor = BackgroundColor(colorCode: codes[i + 2], fullColorSupport: true)
          i += 2
          continue
        }
      }
      if let c = TextColor(colorCode: codes[i]) {
        color = c
      } else if let bg = BackgroundColor(colorCode: codes[i]) {
        backgroundColor = bg
      } else if let style = TextStyle(rawValue: codes[i]) {
        styles.insert(style)
      }
      i += 1
    }
    return TextProperties(textColor: color,
                          backgroundColor: backgroundColor,
                          textStyles: styles)
  }
  
  public var hashValue: Int {
    return (((self.textColor?.hashValue ?? 0) &* 31) + self.textStyles.hashValue) &* 31 +
           (self.backgroundColor?.hashValue ?? 0)
  }
  
  public static func == (lhs: TextProperties, rhs: TextProperties) -> Bool {
    return lhs.textColor == rhs.textColor &&
           lhs.backgroundColor == rhs.backgroundColor &&
           lhs.textStyles == rhs.textStyles
  }
}
