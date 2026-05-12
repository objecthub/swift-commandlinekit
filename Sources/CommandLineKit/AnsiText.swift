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

///
/// `AnsiText` represents text with ANSI formatting properties such as colors
/// and styles. It supports string interpolation and can be composed of plain
/// text, segmented text, or text with annotations (properties like colors and
/// styles).
///
/// Example usage:
/// ```swift
/// let text: AnsiText = "Hello \("World", properties: .init(.red, .bold))"
/// print(text.encodedString) // Outputs ANSI-encoded colored text
/// ```
///
public enum AnsiText: Sendable,
                      Equatable,
                      Hashable,
                      CustomStringConvertible,
                      ExpressibleByStringLiteral,
                      ExpressibleByStringInterpolation,
                      Sequence {
  case plain(String)
  case segmented([AnsiText])
  indirect case annotated(TextProperties, AnsiText)
  
  /// An empty AnsiText value.
  public static let empty: AnsiText = .plain("")
  
  /// Creates a segmented AnsiText from multiple AnsiText values.
  ///
  /// - Parameter texts: A variadic list of AnsiText values to segment together.
  /// - Returns: A segmented AnsiText containing all the provided texts.
  public static func segmented(_ texts: AnsiText...) -> AnsiText {
    return .segmented(texts)
  }
  
  /// Creates an annotated AnsiText from multiple strings with the given properties.
  ///
  /// - Parameters:
  ///   - properties: The text properties to apply to the strings.
  ///   - strings: A variadic list of strings to annotate.
  /// - Returns: An annotated AnsiText with the specified properties applied.
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
  
  /// Creates an annotated AnsiText from multiple AnsiText values with the
  /// given properties.
  ///
  /// - Parameters:
  ///   - properties: The text properties to apply to all the text values.
  ///   - text0: The first AnsiText value.
  ///   - text1: The second AnsiText value.
  ///   - texts: Additional AnsiText values to include.
  /// - Returns: An annotated AnsiText with the specified properties applied
  ///            to all segments.
  public static func annotated(_ properties: TextProperties,
                               _ text0: AnsiText,
                               _ text1: AnsiText,
                               _ texts: AnsiText...) -> AnsiText {
    var res: [AnsiText] = [text0, text1]
    res.append(contentsOf: texts)
    return .annotated(properties, .segmented(res))
  }
  
  /// Specifies horizontal alignment options for text layout.
  public enum Alignment {
    case left
    case right
    case center
  }
  
  /// A normalized representation of `AnsiText` that merges adjacent segments with
  /// identical properties for more efficient storage and processing.
  ///
  /// `Normalized` flattens the hierarchical structure of `AnsiText` into a linear
  /// sequence of property-string pairs, making it easier to manipulate and render
  /// the text.
  public struct Normalized: Sendable,
                            Equatable,
                            Hashable,
                            CustomStringConvertible,
                            Collection,
                            BidirectionalCollection {
    
    /// The segments of this normalized text, each containing text properties
    /// and a string.
    public var segments: [(TextProperties, String)]
    
    /// Initializes a new normalized ANSI text value from a segments array.
    public init(segments: [(TextProperties, String)]) {
      self.init(segments: segments, optimize: true)
    }
    
    /// Initializes a new normalized ANSI text value from a string.
    public init(_ string: String = "", properties: TextProperties = .none) {
      self.init(segments: [(properties, string)], optimize: true)
    }
    
    /// Initializes a new normalized ANSI text value from a string.
    public init(repeating: String, count: Int, properties: TextProperties = .none) {
      self.init(segments: [(properties, String(repeating: repeating, count: count))],
                optimize: true)
    }
    
    /// Initializes a new normalized ANSI text value.
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
    
    /// Appends the given normalized text.
    public mutating func append(_ content: Normalized) {
      if content.isEmpty {
        // Nothing to do
      } else if self.segments.isEmpty {
        self.segments = content.segments
      } else if self.segments.last!.0 == content.segments.first!.0 {
        self.segments[self.segments.count - 1].1 += content.segments.first!.1
        self.segments.append(contentsOf: content.segments[1...])
      } else {
        self.segments.append(contentsOf: content.segments)
      }
    }
    
    /// Appends the given sequence of normalized texts.
    public mutating func append<S>(contentsOf xs: S) where S: Sequence, S.Element == Normalized {
      for content in xs {
        self.append(content)
      }
    }
    
    /// Appends one or more normalized text values to this one.
    ///
    /// - Parameters:
    ///   - content: The normalized text values to append.
    /// - Returns: A new normalized text containing this text followed by the appended content.
    public func appending(_ content: Normalized...) -> Normalized {
      var segments = self.segments
      for norm in content {
        segments.append(contentsOf: norm.segments)
      }
      return Normalized(segments: segments)
    }
    
    /// Appends a sequence of normalized text values and returns a new normalized
    /// text value.
    ///
    /// - Parameters:
    ///   - xs: The sequence of normalized text values to append.
    /// - Returns: A new normalized text containing this text followed by the appended content.
    public func appending<S>(contentsOf xs: S) -> Normalized
                  where S: Sequence, S.Element == Normalized {
      var segments = self.segments
      for x in xs {
        segments.append(contentsOf: x.segments)
      }
      return Normalized(segments: segments)
    }
    
    /// Converts this normalized text back to an AnsiText value.
    public var text: AnsiText {
      var result: [AnsiText] = []
      for segment in self.segments {
        result.append(.annotated(segment.0, .plain(segment.1)))
      }
      return .segmented(result)
    }
    
    /// Returns the total character count of all text segments.
    public var count: Int {
      return self.segments.reduce(0) { result, segment in result + segment.1.count }
    }
    
    /// Splits this normalized text into multiple normalized text values based
    /// on a separator predicate. The result does not contain empty `Normalized`
    /// values.
    ///
    /// - Parameter whereSeparator: A closure that returns `true` for characters
    ///                             that should be treated as separators.
    /// - Returns: An array of normalized text values, split at separator characters.
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
    
    /// Splits this normalized text into tokens separated by whitespace characters.
    ///
    /// - Returns: An array of normalized text values, one for each
    ///            whitespace-separated token.
    public func tokenize() -> [Normalized] {
      return self.split(whereSeparator: \.isWhitespace)
    }
    
    /// Returns the ANSI-encoded string representation with all formatting
    /// codes included. This is suitable for output to a terminal that supports
    /// ANSI escape sequences.
    public var encodedString: String {
      var result = ""
      for (properties, string) in segments {
        result += properties.apply(to: string)
      }
      return result
    }
    
    /// Returns the plain text content without any formatting information.
    ///
    /// This property provides the string representation suitable for contexts
    /// that don't support ANSI formatting.
    public var description: String {
      return segments.map { $0.1 }.joined()
    }
    
    /// Iterator for traversing the characters in a normalized AnsiText.
    public struct Iterator: IteratorProtocol {
      private var segments: [(TextProperties, String)]
      private var segmentIndex: Int
      private var stringIterator: String.Iterator?
      
      init(_ normalized: Normalized) {
        self.segments = normalized.segments
        self.segmentIndex = 0
        if self.segments.isEmpty {
          self.stringIterator = nil
        } else {
          self.stringIterator = self.segments[0].1.makeIterator()
        }
      }
      
      /// Returns the next character in the sequence, or `nil` if the end has been reached.
      public mutating func next() -> (properties: TextProperties, character: Character)? {
        // Try to get next character from current string iterator
        while self.segmentIndex < self.segments.count {
          if let char = self.stringIterator!.next() {
            return (properties: self.segments[self.segmentIndex].0, character: char)
          }
          // Current segment exhausted, move to next segment
          self.segmentIndex += 1
          if self.segmentIndex < self.segments.count {
            self.stringIterator = self.segments[self.segmentIndex].1.makeIterator()
          } else {
            self.stringIterator = nil
          }
        }
        return nil
      }
    }
    
    /// An index into a normalized text's character sequence.
    public struct Index: Comparable {
      fileprivate let segmentIndex: Int
      fileprivate let stringIndex: String.Index
      
      public static func < (lhs: Index, rhs: Index) -> Bool {
        if lhs.segmentIndex != rhs.segmentIndex {
          return lhs.segmentIndex < rhs.segmentIndex
        }
        return lhs.stringIndex < rhs.stringIndex
      }
    }
    
    /// The position of the first character, or `endIndex` if the text is empty.
    public var startIndex: Index {
      for i in self.segments.indices {
        if !self.segments[i].1.isEmpty {
          return Index(segmentIndex: i, stringIndex: self.segments[i].1.startIndex)
        }
      }
      return self.endIndex
    }
    
    /// The position one past the last character.
    public var endIndex: Index {
      if self.segments.isEmpty {
        return Index(segmentIndex: 0, stringIndex: "".startIndex)
      }
      let lastIndex = segments.count - 1
      return Index(segmentIndex: lastIndex, stringIndex: segments[lastIndex].1.endIndex)
    }
    
    /// Returns the position immediately after the given index.
    public func index(after i: Index) -> Index {
      let segment = segments[i.segmentIndex]
      let nextStringIndex = segment.1.index(after: i.stringIndex)
      // If we're still within the current segment, return the next position in it
      if nextStringIndex < segment.1.endIndex {
        return Index(segmentIndex: i.segmentIndex, stringIndex: nextStringIndex)
      }
      // Otherwise, move to the next non-empty segment
      for segmentIndex in (i.segmentIndex + 1)..<segments.count {
        if !segments[segmentIndex].1.isEmpty {
          return Index(segmentIndex: segmentIndex, stringIndex: segments[segmentIndex].1.startIndex)
        }
      }
      // If no more non-empty segments, return endIndex
      return endIndex
    }
    
    /// Returns the position immediately before the given index.
    public func index(before i: Index) -> Index {
      let segment = segments[i.segmentIndex]
      // If we're not at the start of the current segment, return the previous position in it
      if i.stringIndex > segment.1.startIndex {
        return Index(segmentIndex: i.segmentIndex, 
                    stringIndex: segment.1.index(before: i.stringIndex))
      }
      
      // Otherwise, move to the previous non-empty segment
      for segmentIndex in (0..<i.segmentIndex).reversed() {
        if !segments[segmentIndex].1.isEmpty {
          let prevSegment = segments[segmentIndex]
          return Index(segmentIndex: segmentIndex,
                      stringIndex: prevSegment.1.index(before: prevSegment.1.endIndex))
        }
      }
      
      // This shouldn't happen if index(before:) is only called with valid indices
      fatalError("index(before:) called on startIndex")
    }
    
    /// Accesses the character and properties at the specified position.
    public subscript(position: Index) -> (properties: TextProperties, character: Character) {
      let segment = segments[position.segmentIndex]
      return (properties: segment.0, character: segment.1[position.stringIndex])
    }
    
    // MARK: - Sequence Conformance
    
    /// Creates an iterator for traversing the characters in this normalized text.
    ///
    /// This allows Normalized to be used in for-in loops and other sequence operations.
    /// Note that the iterator traverses the plain text content without formatting information.
    ///
    /// - Returns: An iterator over the characters in the text.
    public func makeIterator() -> Iterator {
      return Iterator(self)
    }
    
    /// Checks if two normalized text values are equal by comparing their segments.
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
    
    /// Concatenates two normalized text values.
    ///
    /// - Parameters:
    ///   - lhs: The left-hand side normalized text.
    ///   - rhs: The right-hand side normalized text.
    /// - Returns: A new normalized text containing both inputs concatenated.
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
  
  /// Creates an AnsiText from a string interpolation.
  ///
  /// This initializer is called automatically when using string interpolation syntax.
  public init(stringInterpolation: StringInterpolation) {
    self = .segmented(stringInterpolation.segments)
  }
  
  /// Creates an AnsiText from a plain string.
  ///
  /// - Parameter string: The string to wrap.
  public init(_ string: String) {
    self = .plain(string)
  }
  
  /// Creates an AnsiText from a string literal.
  ///
  /// This initializer enables `AnsiText` to conform to `ExpressibleByStringLiteral`.
  public init(stringLiteral value: String) {
    self = .plain(value)
  }
  
  /// Creates an AnsiText by repeating a character a specified number of times.
  ///
  /// - Parameters:
  ///   - repeating: The character to repeat.
  ///   - count: The number of times to repeat the character.
  ///   - properties: Optional text properties to apply. Defaults to no properties.
  public init(repeating: Character, count: Int, properties: TextProperties = .none) {
    if properties.isEmpty {
      self = .plain(String(repeating: repeating, count: count))
    } else {
      self = .annotated(properties, .plain(String(repeating: repeating, count: count)))
    }
  }
  
  /// Returns the total character count of the text, excluding formatting information.
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
  
  /// Returns the plain text content without any formatting information.
  ///
  /// This property provides the string representation suitable for contexts that don't support ANSI formatting.
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
  
  /// Returns the ANSI-encoded string representation with all formatting codes included.
  ///
  /// This is suitable for output to a terminal that supports ANSI escape sequences.
  public var encodedString: String {
    return self.normalized.encodedString
  }
  
  /// Returns a normalized representation of this text.
  ///
  /// Normalization flattens the hierarchical structure and merges adjacent segments
  /// with identical properties for more efficient processing.
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
  
  /// Iterator for traversing the characters in an AnsiText.
  public struct Iterator: IteratorProtocol {
    private var stringIterator: String.Iterator
    
    init(_ text: AnsiText) {
      self.stringIterator = text.description.makeIterator()
    }
    
    /// Returns the next character in the sequence, or `nil` if the end has been reached.
    public mutating func next() -> Character? {
      return self.stringIterator.next()
    }
  }
  
  /// Creates an iterator for traversing the characters in this AnsiText.
  ///
  /// This allows AnsiText to be used in for-in loops and other sequence operations.
  /// Note that the iterator traverses the plain text content without formatting information.
  ///
  /// - Returns: An iterator over the characters in the text.
  public func makeIterator() -> Iterator {
    return Iterator(self)
  }
  
  /// Concatenates two AnsiText values.
  ///
  /// - Parameters:
  ///   - lhs: The left-hand side text.
  ///   - rhs: The right-hand side text.
  /// - Returns: A segmented AnsiText containing both inputs.
  public static func + (lhs: AnsiText, rhs: AnsiText) -> AnsiText {
    return .segmented([lhs, rhs])
  }
}

extension Array<AnsiText.Normalized?> {
  
  /// Joins the elements of this array with the given separator string and
  /// aligns the result in a field with `maxWidth` characters based on the
  /// `align` parameter. Use `padCharacter` to pad each line individually
  /// on the left and if `fill` is provided also on the right. `fill`
  /// determines the text properties of the padding.
  ///
  /// This method performs word wrapping: when adding a word would exceed `maxWidth`,
  /// a new line is created. `nil` elements force a line break.
  ///
  /// - Parameters:
  ///   - separator: The separator string to use between elements. Defaults to a single space.
  ///   - maxWidth: The maximum width in characters for each line.
  ///   - align: The alignment for the content within the field.
  ///   - padCharacter: The character to use for padding. Defaults to a space.
  ///   - fill: Optional text properties to apply to padding characters.
  /// - Returns: An array of normalized text values, one per line.
  public func joined(separator: String = " ",
                     maxWidth: Int,
                     align: AnsiText.Alignment = .left,
                     padCharacter: Character = " ",
                     fill: TextProperties? = nil) -> [AnsiText.Normalized] {
    let pad = "\(padCharacter)"
    var lines: [AnsiText.Normalized] = []
    var currLine: [AnsiText.Normalized] = []
    var currCount = 0
    func insert() {
      if maxWidth - currCount > 0 {
        var sm = currLine.joined(separator: separator).segments
        switch align {
          case .left:
            if let fill {
              sm.append((fill, String(repeating: pad, count: maxWidth - currCount)))
            }
          case .right:
            sm.insert((fill ?? .none, String(repeating: pad, count: maxWidth - currCount)), at: 0)
          case .center:
            let leftCount = (maxWidth - currCount) / 2
            sm.insert((fill ?? .none, String(repeating: pad, count: leftCount)), at: 0)
            if let fill {
              sm.append((fill, String(repeating: pad, count: maxWidth - currCount - leftCount)))
            }
        }
        lines.append(AnsiText.Normalized(segments: sm))
      } else {
        lines.append(currLine.joined(separator: separator))
      }
      currLine = []
      currCount = 0
    }
    for word in self {
      if let word {
        let wordCount = word.count
        if currCount > 0 {
          if currCount + wordCount >= maxWidth {
            insert()
            currLine = [word]
            currCount = wordCount
          } else {
            currLine.append(word)
            currCount += wordCount + 1
          }
        } else {
          currLine.append(word)
          currCount += wordCount
        }
      } else {
        insert()
      }
    }
    if !currLine.isEmpty {
      insert()
    }
    return lines
  }
}

extension Array<AnsiText.Normalized> {
  
  /// Joins the elements of this array with the given separator string and
  /// aligns the result in a field with `maxWidth` characters based on the
  /// `align` parameter. Use `padCharacter` to pad each line individually
  /// on the left and if `fill` is provided also on the right. `fill`
  /// determines the text properties of the padding.
  ///
  /// This method performs word wrapping: when adding a word would exceed `maxWidth`,
  /// a new line is created.
  ///
  /// - Parameters:
  ///   - separator: The separator string to use between elements. Defaults to a single space.
  ///   - maxWidth: The maximum width in characters for each line.
  ///   - align: The alignment for the content within the field.
  ///   - padCharacter: The character to use for padding. Defaults to a space.
  ///   - fill: Optional text properties to apply to padding characters.
  /// - Returns: An array of normalized text values, one per line.
  public func joined(separator: String = " ",
                     maxWidth: Int,
                     align: AnsiText.Alignment = .left,
                     padCharacter: Character = " ",
                     fill: TextProperties? = nil) -> [AnsiText.Normalized] {
    return (self as [AnsiText.Normalized?]).joined(separator: separator,
                                                   maxWidth: maxWidth,
                                                   align: align,
                                                   padCharacter: padCharacter,
                                                   fill: fill)
  }
  
  /// Joins the normalized AnsiText objects together interjecting a separator.
  /// This variant of `joined` will infer the properties of the separator by finding
  /// the intersection of properties from adjacent segments.
  ///
  /// - Parameter separator: The separator string to place between elements.
  /// - Returns: A single normalized text value containing all elements joined by the separator.
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
  
  /// Joins the normalized AnsiText objects together interjecting an AnsiText separator.
  ///
  /// - Parameter separator: The AnsiText separator to place between elements. Defaults to empty.
  /// - Returns: A single normalized text value containing all elements joined by the separator.
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
  /// This variant of `joined` will infer the properties of the separator by finding
  /// the intersection of properties from adjacent segments.
  ///
  /// - Parameter separator: The separator string to place between elements.
  /// - Returns: A single AnsiText value containing all elements joined by the separator.
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
  ///
  /// - Parameter separator: The AnsiText separator to place between elements. Defaults to empty.
  /// - Returns: A single AnsiText value containing all elements joined by the separator.
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
