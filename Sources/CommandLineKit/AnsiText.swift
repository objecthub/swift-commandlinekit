//
//  AnnotatedText.swift
//  CommandLineKit
//
//  Created by Matthias Zenger on 10/05/2026.
//  Copyright © 2026 Matthias Zenger. All rights reserved.
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

public enum AnsiText: Sendable,
                      Equatable,
                      Hashable,
                      CustomStringConvertible,
                      ExpressibleByStringLiteral,
                      ExpressibleByStringInterpolation {
  case plain(String)
  case segmented([AnsiText])
  indirect case annotated(TextProperties, AnsiText)
  
  public static let empty: AnsiText = .plain("")
  
  public static func segmented(_ texts: AnsiText...) -> AnsiText {
    return .segmented(texts)
  }
  
  public static func annotated(_ properties: TextProperties, _ strings: String...) -> AnsiText {
    switch strings.count {
      case 0:
        return .annotated(properties, .empty)
      case 1:
        return .annotated(properties, .plain(strings[0]))
      default:
        return .annotated(properties, .segmented(strings.map(AnsiText.plain)))
    }
  }
  
  public static func annotated(_ properties: TextProperties,
                               _ text0: AnsiText,
                               _ text1: AnsiText,
                               _ texts: AnsiText...) -> AnsiText {
    var res: [AnsiText] = [text0, text1]
    res.append(contentsOf: texts)
    return .annotated(properties, .segmented(res))
  }
  
  public enum Alignment {
    case left
    case right
    case center
  }
  
  public struct Normalized: Sendable, Equatable, Hashable {
    public let segments: [(TextProperties, String)]
    
    init(segments: [(TextProperties, String)], optimize: Bool = true) {
      if optimize && segments.count > 1 {
        var optimized: [(TextProperties, String)] = []
        var i = 0
        while i < segments.count && segments[i].1.isEmpty {
          i += 1
        }
        if i < segments.count {
          var current = segments[i]
          i += 1
          while i < segments.count {
            if segments[i].1.isEmpty {
              // ignore segment
            } else if segments[i].0 == current.0 {
              current.1 += segments[i].1
            } else {
              optimized.append(current)
              current = segments[i]
            }
            i += 1
          }
          optimized.append(current)
        }
        self.segments = optimized
      } else {
        self.segments = segments
      }
    }
    
    public func hash(into hasher: inout Hasher) {
      for segment in self.segments {
        hasher.combine(segment.0)
        hasher.combine(segment.1)
      }
    }
    
    public func append(optimize: Bool = true, _ content: Normalized...) -> Normalized {
      var segments = self.segments
      for norm in content {
        segments.append(contentsOf: norm.segments)
      }
      return Normalized(segments: segments, optimize: optimize)
    }
    
    public var text: AnsiText {
      var result: [AnsiText] = []
      for segment in self.segments {
        result.append(.annotated(segment.0, .plain(segment.1)))
      }
      return .segmented(result)
    }
    
    public var count: Int {
      return self.segments.reduce(0) { result, segment in result + segment.1.count }
    }
    
    public func split(whereSeparator: (Character) -> Bool) -> [Normalized] {
      var tokens: [Normalized] = []
      var carryover: [(TextProperties, String)] = []
      for segment in self.segments {
        let parts = segment.1.split(omittingEmptySubsequences: false,
                                    whereSeparator: whereSeparator)
        guard parts.count > 0 else {
          continue
        }
        if parts.count == 1 {
          if parts.first!.isEmpty {
            if carryover.count > 0 {
              tokens.append(Normalized(segments: carryover))
              carryover = []
            }
          } else {
            carryover.append((segment.0, String(parts.first!)))
          }
        } else {
          for (i, part) in parts.enumerated() {
            if i == 0 {
              if part.isEmpty {
                if carryover.count > 0 {
                  tokens.append(Normalized(segments: carryover))
                }
              } else {
                carryover.append((segment.0, String(part)))
                tokens.append(Normalized(segments: carryover))
              }
              carryover = []
            } else if i == parts.count - 1 {
              if part.isEmpty {
                // do nothing
              } else {
                carryover.append((segment.0, String(part)))
              }
            } else if part.isEmpty {
              // do nothing
            } else {
              tokens.append(Normalized(segments: [(segment.0, String(part))]))
            }
          }
        }
      }
      if carryover.count > 0 {
        tokens.append(Normalized(segments: carryover))
      }
      return tokens
    }
    
    public func tokenize() -> [Normalized] {
      return self.split(whereSeparator: \.isWhitespace)
    }
    
    public static func == (lhs: Normalized, rhs: Normalized) -> Bool {
      guard lhs.segments.count == rhs.segments.count else {
        return false
      }
      for i in lhs.segments.indices {
        if lhs.segments[i].0 != rhs.segments[i].0 ||
            lhs.segments[i].1 != rhs.segments[i].1 {
          return false
        }
      }
      return true
    }
    
    public static func + (lhs: Normalized, rhs: Normalized) -> Normalized {
      var segments = lhs.segments
      segments.append(contentsOf: rhs.segments)
      return Normalized(segments: segments)
    }
  }
  
  // The nested interpolation builder
  public struct StringInterpolation: StringInterpolationProtocol {
    var segments: [AnsiText] = []
    
    // Called once upfront with capacity hints
    public init(literalCapacity: Int, interpolationCount: Int) {
      self.segments.reserveCapacity(literalCapacity)
    }
    
    // Called for each plain string segment
    mutating public func appendLiteral(_ literal: String) {
      segments.append(.plain(literal))
    }
    
    // Called for each \(...) expression
    mutating public func appendInterpolation(_ value: String,
                                             properties: TextProperties = .none) {
      segments.append(.annotated(properties, .plain(value)))
    }
    
    // Called for each \(...) expression
    mutating public func appendInterpolation(_ value: AnsiText,
                                             properties: TextProperties = .none) {
      segments.append(.annotated(properties, value))
    }
    
    // Called for each \(...) expression
    mutating public func appendInterpolation(_ value: Any) {
      segments.append(.plain("\(value)"))
    }
  }
  
  public init(stringInterpolation: StringInterpolation) {
    self = .segmented(stringInterpolation.segments)
  }
  
  public init(_ string: String) {
    self = .plain(string)
  }
  
  public init(stringLiteral value: String) {
    self = .plain(value)
  }
  
  public init(repeating: Character, count: Int, properties: TextProperties = .none) {
    if properties.isEmpty {
      self = .plain(String(repeating: repeating, count: count))
    } else {
      self = .annotated(properties, .plain(String(repeating: repeating, count: count)))
    }
  }
  
  public var count: Int {
    switch self {
      case .plain(let str):
        return str.count
      case .segmented(let segmented):
        return segmented.reduce(0) { result, text in text.count + result }
      case .annotated(_, let text):
        return text.count
    }
  }
  
  public var description: String {
    switch self {
      case .plain(let str):
        return str
      case .annotated(_, let text):
        return text.description
      case .segmented(let segments):
        return segments.reduce("", { (str, txt) in str + txt.description })
    }
  }
  
  public var normalized: Normalized {
    var result: [(TextProperties, String)] = []
    self.normalize(properties: .none, enterInto: &result)
    return Normalized(segments: result)
  }
  
  private func normalize(properties: TextProperties, enterInto: inout [(TextProperties, String)]) {
    switch self {
      case .plain(let str):
        enterInto.append((properties, str))
      case .segmented(let texts):
        for text in texts {
          text.normalize(properties: properties, enterInto: &enterInto)
        }
      case .annotated(let textProperties, let text):
        text.normalize(properties: properties.with(textProperties), enterInto: &enterInto)
    }
  }
  
  public static func + (lhs: AnsiText, rhs: AnsiText) -> AnsiText {
    return .segmented([lhs, rhs])
  }
}

extension Array<AnsiText.Normalized?> {
  
  public func joined(separator: String,
                     maxWidth: Int,
                     align: AnsiText.Alignment = .left,
                     fill: TextProperties? = nil) -> [AnsiText.Normalized] {
    var lines: [AnsiText.Normalized] = []
    var currentLine: [AnsiText.Normalized] = []
    var currentCount = 0
    func insert() {
      if maxWidth - currentCount > 0 {
        var segments = currentLine.joined(separator: " ").segments
        switch align {
          case .left:
            if let fill {
              segments.append((fill, String(repeating: " ", count: maxWidth - currentCount)))
            }
          case .right:
            segments.insert((fill ?? .none, String(repeating: " ", count: maxWidth - currentCount)),
                            at: 0)
          case .center:
            let leftCount = (maxWidth - currentCount) / 2
            segments.insert((fill ?? .none, String(repeating: " ", count: leftCount)), at: 0)
            if let fill {
              segments.append((fill,
                               String(repeating: " ", count: maxWidth - currentCount - leftCount)))
            }
        }
        lines.append(AnsiText.Normalized(segments: segments))
      } else {
        lines.append(currentLine.joined(separator: " "))
      }
      currentLine = []
      currentCount = 0
    }
    for word in self {
      if let word {
        let wordCount = word.count
        if currentCount > 0 {
          if currentCount + wordCount >= maxWidth {
            insert()
            currentLine = [word]
            currentCount = wordCount
          } else {
            currentLine.append(word)
            currentCount += wordCount + 1
          }
        } else {
          currentLine.append(word)
          currentCount += wordCount
        }
      } else {
        insert()
      }
    }
    if !currentLine.isEmpty {
      insert()
    }
    return lines
  }
}

extension Array<AnsiText.Normalized> {
  
  /// Joins the normalized AnsiText objects together interjecting a separator.
  /// This variant of `joined` will infer the properties of the separator.
  public func joined(separator: String) -> AnsiText.Normalized {
    var result: [(TextProperties, String)] = []
    var carryoverProperties: TextProperties? = nil
    for i in self.indices {
      let segments = self[i].segments
      if let carryoverProperties {
        let properties = carryoverProperties.intersect(with: segments.first!.0)
        result.append((properties, separator))
      }
      result.append(contentsOf: segments)
      carryoverProperties = segments.last!.0
    }
    return AnsiText.Normalized(segments: result)
  }
  
  /// Joins the AnsiText objects together interjecting an AnsiText separator.
  public func joined(separator: AnsiText = .segmented([])) -> AnsiText.Normalized {
    let normalizedSeparator = separator.normalized.segments
    var result: [(TextProperties, String)] = []
    var first = true
    for normalized in self {
      if first {
        first = false
      } else {
        result.append(contentsOf: normalizedSeparator)
      }
      result.append(contentsOf: normalized.segments)
    }
    return AnsiText.Normalized(segments: result)
  }
}

extension Array<AnsiText> {
  
  /// Joins the AnsiText objects together interjecting a separator.
  /// This variant of `joined` will infer the properties of the separator.
  public func joined(separator: String) -> AnsiText {
    var result: [(TextProperties, String)] = []
    var carryoverProperties: TextProperties? = nil
    for i in self.indices {
      let segments = self[i].normalized.segments
      if let carryoverProperties {
        let properties = carryoverProperties.intersect(with: segments.first!.0)
        result.append((properties, separator))
      }
      result.append(contentsOf: segments)
      carryoverProperties = segments.last!.0
    }
    return AnsiText.Normalized(segments: result).text
  }
  
  /// Joins the AnsiText objects together interjecting an AnsiText separator.
  public func joined(separator: AnsiText = .segmented([])) -> AnsiText {
    let normalizedSeparator = separator.normalized.segments
    var result: [(TextProperties, String)] = []
    var first = true
    for text in self {
      if first {
        first = false
      } else {
        result.append(contentsOf: normalizedSeparator)
      }
      result.append(contentsOf: text.normalized.segments)
    }
    return AnsiText.Normalized(segments: result).text
  }
}
