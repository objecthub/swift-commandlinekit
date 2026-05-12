//
//  AnsiTextTests.swift
//  CommandLineKitTests
//
//  Created by Matthias Zenger on 10/05/2026.
//  Copyright © 2026 Matthias Zenger. All rights reserved.
//

import XCTest
@testable import CommandLineKit

class AnsiTextTests: XCTestCase {
  
  // MARK: - Basic Construction Tests
  
  func testPlainTextCreation() {
    let text = AnsiText.plain("Hello")
    XCTAssertEqual(text.description, "Hello")
    XCTAssertEqual(text.count, 5)
  }
  
  func testEmptyText() {
    let text = AnsiText.empty
    XCTAssertEqual(text.description, "")
    XCTAssertEqual(text.count, 0)
  }
  
  func testStringLiteralConformance() {
    let text: AnsiText = "Hello, World!"
    XCTAssertEqual(text.description, "Hello, World!")
    XCTAssertEqual(text.count, 13)
  }
  
  func testRepeatingCharacter() {
    let text = AnsiText(repeating: "*", count: 5)
    XCTAssertEqual(text.description, "*****")
    XCTAssertEqual(text.count, 5)
  }
  
  func testRepeatingCharacterWithProperties() {
    let properties = TextProperties(.red)
    let text = AnsiText(repeating: "-", count: 3, properties: properties)
    XCTAssertEqual(text.description, "---")
    XCTAssertEqual(text.count, 3)
  }
  
  // MARK: - Segmented Text Tests
  
  func testSegmentedTextCreation() {
    let text = AnsiText.segmented(.plain("Hello"), .plain(" "), .plain("World"))
    XCTAssertEqual(text.description, "Hello World")
    XCTAssertEqual(text.count, 11)
  }
  
  func testSegmentedCount() {
    let text = AnsiText.segmented([
      .plain("First"),
      .plain("Second"),
      .plain("Third")
    ])
    XCTAssertEqual(text.count, 16)
    XCTAssertEqual(text.description, "FirstSecondThird")
  }
  
  func testEmptySegments() {
    let text = AnsiText.segmented([])
    XCTAssertEqual(text.count, 0)
    XCTAssertEqual(text.description, "")
  }
  
  // MARK: - Annotated Text Tests
  
  func testAnnotatedTextSingleString() {
    let properties = TextProperties(.blue)
    let text = AnsiText.annotated(properties, "Blue text")
    XCTAssertEqual(text.description, "Blue text")
    XCTAssertEqual(text.count, 9)
  }
  
  func testAnnotatedTextMultipleStrings() {
    let properties = TextProperties(.green)
    let text = AnsiText.annotated(properties, "Hello", " ", "World")
    XCTAssertEqual(text.description, "Hello World")
    XCTAssertEqual(text.count, 11)
  }
  
  func testAnnotatedTextNoStrings() {
    let properties = TextProperties(.red)
    let text = AnsiText.annotated(properties)
    XCTAssertEqual(text.description, "")
    XCTAssertEqual(text.count, 0)
  }
  
  func testAnnotatedTextWithAnsiText() {
    let properties = TextProperties(.yellow)
    let text = AnsiText.annotated(properties, .plain("Hello"), .plain("World"))
    XCTAssertEqual(text.description, "HelloWorld")
    XCTAssertEqual(text.count, 10)
  }
  
  func testNestedAnnotations() {
    let properties1 = TextProperties(.red)
    let properties2 = TextProperties(textStyles: [.bold])
    let text = AnsiText.annotated(properties1, 
                                   .annotated(properties2, .plain("Bold Red")))
    XCTAssertEqual(text.description, "Bold Red")
    XCTAssertEqual(text.count, 8)
  }
  
  // MARK: - String Interpolation Tests
  
  func testStringInterpolationPlain() {
    let text: AnsiText = "Hello \("World")"
    XCTAssertEqual(text.description, "Hello World")
  }
  
  func testStringInterpolationWithProperties() {
    let properties = TextProperties(backgroundColor: BackgroundColor.cyan)
    let text: AnsiText = "Hello \("World", properties: properties)"
    XCTAssertEqual(text.description, "Hello World")
    XCTAssertEqual(text.count, 11)
  }
  
  func testStringInterpolationWithAnsiText() {
    let inner: AnsiText = "Inner"
    let text: AnsiText = "Outer \(inner) Text"
    XCTAssertEqual(text.description, "Outer Inner Text")
  }
  
  func testStringInterpolationWithAny() {
    let number = 42
    let text: AnsiText = "The answer is \(number)"
    XCTAssertEqual(text.description, "The answer is 42")
  }
  
  // MARK: - Normalization Tests
  
  func testNormalizedPlain() {
    let text = AnsiText.plain("Hello")
    let normalized = text.normalized
    XCTAssertEqual(normalized.segments.count, 1)
    XCTAssertEqual(normalized.segments[0].0, .none)
    XCTAssertEqual(normalized.segments[0].1, "Hello")
    XCTAssertEqual(normalized.count, 5)
  }
  
  func testNormalizedAnnotated() {
    let properties = TextProperties(.red)
    let text = AnsiText.annotated(properties, "Red text")
    let normalized = text.normalized
    XCTAssertEqual(normalized.segments.count, 1)
    XCTAssertEqual(normalized.segments[0].0, properties)
    XCTAssertEqual(normalized.segments[0].1, "Red text")
  }
  
  func testNormalizedSegmented() {
    let text = AnsiText.segmented([
      .plain("Hello"),
      .plain(" "),
      .plain("World")
    ])
    let normalized = text.normalized
    XCTAssertEqual(normalized.segments.count, 1)
    XCTAssertEqual(normalized.count, 11)
    let properties = TextProperties(textColor: .red, backgroundColor: .green)
    let text2 = AnsiText.segmented([
      .annotated(properties, .plain("Hello")),
      .plain(" "),
      .annotated(properties, .plain("World"))
    ])
    let normalized2 = text2.normalized
    XCTAssertEqual(normalized2.segments.count, 3)
    XCTAssertEqual(normalized2.count, 11)
  }
  
  func testNormalizedOptimization() {
    // Adjacent segments with same properties should be merged
    let properties = TextProperties(.blue)
    let text = AnsiText.segmented([
      .annotated(properties, .plain("Hello")),
      .annotated(properties, .plain(" World"))
    ])
    let normalized = text.normalized
    XCTAssertEqual(normalized.segments.count, 1)
    XCTAssertEqual(normalized.segments[0].1, "Hello World")
  }
  
  func testNormalizedEmptySegmentsRemoved() {
    let properties = TextProperties(.green)
    let text = AnsiText.segmented([
      .plain(""),
      .annotated(properties, "Text"),
      .plain("")
    ])
    let normalized = text.normalized
    XCTAssertEqual(normalized.segments.count, 1)
    XCTAssertEqual(normalized.segments[0].1, "Text")
  }
  
  func testNormalizedTextConversion() {
    let properties = TextProperties(backgroundColor: .magenta)
    let normalized = AnsiText.Normalized(segments: [(properties, "Test")])
    let text = normalized.text
    XCTAssertEqual(text.description, "Test")
    XCTAssertEqual(text.count, 4)
  }
  
  // MARK: - Tokenization Tests
  
  func testTokenizeSingleWord() {
    let text = AnsiText.plain("Hello")
    let normalized = text.normalized
    XCTAssertEqual(normalized.count, 5)
    XCTAssertEqual(normalized.segments.count, 1)
    if normalized.segments.count > 0 {
      XCTAssertEqual(normalized.segments[0].1, "Hello")
    }
    let tokens = text.normalized.tokenize()
    XCTAssertEqual(tokens.count, 1)
    if tokens.count > 0 {
      XCTAssertEqual(tokens[0].segments[0].1, "Hello")
    }
  }
  
  func testTokenizeMultipleWords() {
    let text = AnsiText.plain("Hello World Test")
    let tokens = text.normalized.tokenize()
    XCTAssertEqual(tokens.count, 3)
    XCTAssertEqual(tokens[0].segments[0].1, "Hello")
    XCTAssertEqual(tokens[1].segments[0].1, "World")
    XCTAssertEqual(tokens[2].segments[0].1, "Test")
  }
  
  func testTokenizeWithMultipleSpaces() {
    let text = AnsiText.plain(" Hello   World  ")
    let tokens = text.normalized.tokenize()
    XCTAssertEqual(tokens.count, 2)
    XCTAssertEqual(tokens[0].segments[0].1, "Hello")
    XCTAssertEqual(tokens[1].segments[0].1, "World")
  }
  
  func testTokenizeWithTabs() {
    let text = AnsiText.plain("Hello\tWorld")
    let tokens = text.normalized.tokenize()
    XCTAssertEqual(tokens.count, 2)
    XCTAssertEqual(tokens[0].segments[0].1, "Hello")
    XCTAssertEqual(tokens[1].segments[0].1, "World")
  }
  
  func testTokenizeEmptyString() {
    let text = AnsiText.plain("")
    let tokens = text.normalized.tokenize()
    XCTAssertEqual(tokens.count, 0)
  }
  
  func testTokenizePreservesProperties() {
    let properties = TextProperties(.red)
    let text = AnsiText.annotated(properties, "Hello World")
    let tokens = text.normalized.tokenize()
    XCTAssertEqual(tokens.count, 2)
    XCTAssertEqual(tokens[0].segments[0].0, properties)
    XCTAssertEqual(tokens[1].segments[0].0, properties)
  }
  
  // MARK: - Split Tests
  
  func testSplitBySeparator() {
    let text = AnsiText.plain("a,b,c")
    let parts = text.normalized.split(whereSeparator: { $0 == "," })
    XCTAssertEqual(parts.count, 3)
    XCTAssertEqual(parts[0].segments[0].1, "a")
    XCTAssertEqual(parts[1].segments[0].1, "b")
    XCTAssertEqual(parts[2].segments[0].1, "c")
  }
  
  func testSplitWithEmptyParts() {
    let text = AnsiText.plain("a,,c")
    let parts = text.normalized.split(whereSeparator: { $0 == "," })
    XCTAssertEqual(parts.count, 2)
    XCTAssertEqual(parts[0].segments[0].1, "a")
    XCTAssertEqual(parts[1].segments[0].1, "c")
  }
  
  func testSplitPreservesProperties() {
    let properties = TextProperties(.blue)
    let text = AnsiText.annotated(properties, "a:b:c")
    let parts = text.normalized.split(whereSeparator: { $0 == ":" })
    XCTAssertEqual(parts.count, 3)
    for part in parts {
      XCTAssertEqual(part.segments[0].0, properties)
    }
  }
  
  // MARK: - Array Joining Tests (String separator with inferred properties)
  
  func testJoinAnsiTextArrayWithStringSeparator() {
    let texts = [
      AnsiText.plain("First"),
      AnsiText.plain("Second"),
      AnsiText.plain("Third")
    ]
    let joined = texts.joined(separator: ", ")
    XCTAssertEqual(joined.description, "First, Second, Third")
  }
  
  func testJoinAnsiTextArrayEmptyArray() {
    let texts: [AnsiText] = []
    let joined = texts.joined(separator: ", ")
    XCTAssertEqual(joined.description, "")
  }
  
  func testJoinAnsiTextArraySingleElement() {
    let texts = [AnsiText.plain("Only")]
    let joined = texts.joined(separator: ", ")
    XCTAssertEqual(joined.description, "Only")
  }
  
  func testJoinAnsiTextArrayWithAnsiSeparator() {
    let separator = AnsiText.plain(" - ")
    let texts = [
      AnsiText.plain("First"),
      AnsiText.plain("Second")
    ]
    let joined = texts.joined(separator: separator)
    XCTAssertEqual(joined.description, "First - Second")
  }
  
  // MARK: - Array Joining Tests (Normalized)
  
  func testJoinNormalizedArrayWithStringSeparator() {
    let normalized = [
      AnsiText.plain("One").normalized,
      AnsiText.plain("Two").normalized,
      AnsiText.plain("Three").normalized
    ]
    let joined = normalized.joined(separator: ", ")
    XCTAssertEqual(joined.count, 15) // "One, Two, Three"
  }
  
  func testJoinNormalizedArrayWithAnsiSeparator() {
    let separator = AnsiText.annotated(TextProperties(textColor: .red), .plain(" | "))
    let normalized = [
      AnsiText.plain("A").normalized,
      AnsiText.plain("B").normalized
    ]
    let joined = normalized.joined(separator: separator)
    XCTAssertEqual(joined.segments.count, 3) // A, separator, B
    XCTAssertEqual(joined.text.description, "A | B")
  }
  
  func testJoinNormalizedArrayPropertiesInferred() {
    let properties = TextProperties(.red)
    let properties2 = TextProperties(.blue)
    let normalized = [
      AnsiText.annotated(properties, "Red").normalized,
      AnsiText.annotated(properties2, "Text").normalized
    ]
    let joined = normalized.joined(separator: " ")
    XCTAssertEqual(joined.segments.count, 3)
    if joined.segments.count > 1 {
      XCTAssertEqual(joined.segments[1].1, " ")
    }
    let normalized2 = [
      AnsiText.annotated(properties, "Red").normalized,
      AnsiText.annotated(properties, "Text").normalized
    ]
    let joined2 = normalized2.joined(separator: " ")
    // The separator should inherit the red property
    XCTAssertEqual(joined2.segments.count, 1)
    if joined2.segments.count > 0 {
      XCTAssertEqual(joined2.segments[0].1, "Red Text")
      XCTAssertEqual(joined2.segments[0].0, properties)
    }
  }
  
  // MARK: - Alignment Tests
  
  func testJoinedWithMaxWidthLeftAlign() {
    let words: [AnsiText.Normalized?] = [
      AnsiText.plain("Hello").normalized,
      AnsiText.plain("World").normalized
    ]
    let lines = words.joined(separator: " ", maxWidth: 20, align: .left)
    XCTAssertEqual(lines.count, 1)
    XCTAssertEqual(lines[0].count, 11)
    let lines2 = words.joined(separator: " ",
                              maxWidth: 20,
                              align: .left,
                              fill: TextProperties(.red))
    XCTAssertEqual(lines2.count, 1)
    XCTAssertEqual(lines2[0].count, 20) // Should be padded to maxWidth
  }
  
  func testJoinedWithMaxWidthRightAlign() {
    let words: [AnsiText.Normalized?] = [
      AnsiText.plain("Hi").normalized
    ]
    let lines = words.joined(separator: " ", maxWidth: 10, align: .right)
    XCTAssertEqual(lines.count, 1)
    XCTAssertEqual(lines[0].count, 10)
    // First segment should be spaces for right alignment
  }
  
  func testJoinedWithMaxWidthCenterAlign() {
    let words: [AnsiText.Normalized?] = [
      AnsiText.plain("Test").normalized
    ]
    let lines = words.joined(separator: " ", maxWidth: 10, align: .center)
    XCTAssertEqual(lines.count, 1)
    XCTAssertEqual(lines[0].count, 7)
    let lines2 = words.joined(separator: " ",
                              maxWidth: 10,
                              align: .center,
                              fill: TextProperties(.green))
    XCTAssertEqual(lines2.count, 1)
    XCTAssertEqual(lines2[0].count, 10)
  }
  
  func testJoinedWithMaxWidthWrapping() {
    let words: [AnsiText.Normalized?] = [
      AnsiText.plain("First").normalized,
      AnsiText.plain("Second").normalized,
      AnsiText.plain("Third").normalized,
      AnsiText.plain("Fourth").normalized,
      AnsiText.plain("Sixth").normalized
    ]
    let lines = words.joined(separator: " ", maxWidth: 15, align: .left)
    XCTAssertTrue(lines.count == 3) // Should wrap to multiple lines
  }
  
  func testJoinedWithNilSeparators() {
    let words: [AnsiText.Normalized?] = [
      AnsiText.plain("Line1").normalized,
      nil,
      AnsiText.plain("Line2").normalized
    ]
    let lines = words.joined(separator: " ", maxWidth: 20, align: .left)
    XCTAssertEqual(lines.count, 2) // nil should create line break
  }
  
  func testJoinedWithFillProperties() {
    let fillProps = TextProperties(.blue)
    let words: [AnsiText.Normalized?] = [
      AnsiText.plain("Test").normalized
    ]
    let lines = words.joined(separator: " ", maxWidth: 10, align: .left, fill: fillProps)
    XCTAssertEqual(lines.count, 1)
    XCTAssertEqual(lines[0].text.description, "Test      ")
    XCTAssertEqual(lines[0].count, 10)
    // Last segment should have fill properties
    XCTAssertEqual(lines[0].segments.last?.0, fillProps)
  }
  
  // MARK: - Complex Integration Tests
  
  func testComplexNestedStructure() {
    let props1 = TextProperties(.red)
    let props2 = TextProperties(.blue)
    let text = AnsiText.segmented([
      .annotated(props1, "Red"),
      .plain(" "),
      .annotated(props2, "Blue"),
      .plain(" "),
      .segmented([
        .plain("Plain"),
        .annotated(props1, "Red again")
      ])
    ])
    XCTAssertEqual(text.description, "Red Blue PlainRed again")
    let normalized = text.normalized
    XCTAssertTrue(normalized.segments.count > 0)
  }
  
  func testNormalizedCountMatchesOriginal() {
    let text: AnsiText = "Hello \("World", properties: TextProperties(.green))"
    XCTAssertEqual(text.count, text.normalized.count)
  }
  
  func testRoundTripNormalization() {
    let properties = TextProperties(.yellow)
    let original = AnsiText.annotated(properties, "Test text")
    let normalized = original.normalized
    let reconstructed = normalized.text
    XCTAssertEqual(original.description, reconstructed.description)
    XCTAssertEqual(original.count, reconstructed.count)
  }
  
  func testEmptySegmentsInJoin() {
    let texts = [
      AnsiText.empty,
      AnsiText.plain("Text"),
      AnsiText.empty
    ]
    let joined = texts.joined(separator: ",")
    XCTAssertEqual(joined.description, ",Text,")
  }
  
  func testPropertiesMerging() {
    let props1 = TextProperties(.red)
    let props2 = TextProperties(textStyles: [.bold])
    let text = AnsiText.annotated(props1, .annotated(props2, "Bold Red"))
    let normalized = text.normalized
    // Should have both properties merged
    XCTAssertEqual(normalized.segments.count, 1)
    XCTAssertTrue(normalized.segments[0].0.textColor == props1.textColor)
    XCTAssertTrue(normalized.segments[0].0.textStyles.contains(.bold))
  }
  
  // MARK: - Iterator Tests (AnsiText)
  
  func testAnsiTextIteratorPlain() {
    let text = AnsiText.plain("Hello")
    var chars: [Character] = []
    for char in text {
      chars.append(char)
    }
    XCTAssertEqual(chars, Array("Hello"))
  }
  
  func testAnsiTextIteratorEmpty() {
    let text = AnsiText.empty
    var chars: [Character] = []
    for char in text {
      chars.append(char)
    }
    XCTAssertEqual(chars, [])
  }
  
  func testAnsiTextIteratorAnnotated() {
    let properties = TextProperties(.red)
    let text = AnsiText.annotated(properties, "Test")
    var chars: [Character] = []
    for char in text {
      chars.append(char)
    }
    XCTAssertEqual(chars, Array("Test"))
  }
  
  func testAnsiTextIteratorSegmented() {
    let text = AnsiText.segmented([
      .plain("Hello"),
      .plain(" "),
      .plain("World")
    ])
    var chars: [Character] = []
    for char in text {
      chars.append(char)
    }
    XCTAssertEqual(chars, Array("Hello World"))
  }
  
  func testAnsiTextIteratorComplex() {
    let props = TextProperties(.blue)
    let text = AnsiText.segmented([
      .annotated(props, "First"),
      .plain(" "),
      .annotated(props, .segmented([.plain("Second"), .plain(" Third")]))
    ])
    var chars: [Character] = []
    for char in text {
      chars.append(char)
    }
    XCTAssertEqual(chars, Array("First Second Third"))
  }
  
  func testAnsiTextIteratorFirstAndLast() {
    let text: AnsiText = "Hello World"
    let chars = Array(text)
    XCTAssertEqual(chars.first, "H")
    XCTAssertEqual(chars.last, "d")
  }
  
  func testAnsiTextIteratorEmptyFirstAndLast() {
    let text = AnsiText.empty
    let chars = Array(text)
    XCTAssertNil(chars.first)
    XCTAssertNil(chars.last)
  }
  
  func testAnsiTextIteratorFilter() {
    let text = AnsiText.plain("Hello123")
    let letters = text.filter { $0.isLetter }
    XCTAssertEqual(Array(letters), Array("Hello"))
  }
  
  func testAnsiTextIteratorMap() {
    let text = AnsiText.plain("abc")
    let uppercased = text.map { $0.uppercased() }
    XCTAssertEqual(uppercased, ["A", "B", "C"])
  }
  
  func testAnsiTextIteratorContains() {
    let text: AnsiText = "Hello World"
    XCTAssertTrue(text.contains(where: { $0 == "H" }))
    XCTAssertTrue(text.contains(where: { $0 == " " }))
    XCTAssertFalse(text.contains(where: { $0 == "z" }))
  }
  
  func testAnsiTextIteratorCount() {
    let text = AnsiText.plain("Hello")
    var count = 0
    for _ in text {
      count += 1
    }
    XCTAssertEqual(count, 5)
    XCTAssertEqual(count, text.count)
  }
  
  // MARK: - Iterator Tests (Normalized)
  
  func testNormalizedIteratorSingleSegment() {
    let normalized = AnsiText.plain("Hello").normalized
    var chars: [Character] = []
    for item in normalized {
      chars.append(item.character)
    }
    XCTAssertEqual(chars, Array("Hello"))
  }
  
  func testNormalizedIteratorEmpty() {
    let normalized = AnsiText.empty.normalized
    var chars: [Character] = []
    for item in normalized {
      chars.append(item.character)
    }
    XCTAssertEqual(chars, [])
  }
  
  func testNormalizedIteratorMultipleSegments() {
    let props1 = TextProperties(.red)
    let props2 = TextProperties(.blue)
    let text = AnsiText.segmented([
      .annotated(props1, "Red"),
      .plain(" "),
      .annotated(props2, "Blue")
    ])
    let normalized = text.normalized
    var chars: [Character] = []
    for item in normalized {
      chars.append(item.character)
    }
    XCTAssertEqual(chars, Array("Red Blue"))
  }
  
  func testNormalizedIteratorEmptySegments() {
    let segments: [(TextProperties, String)] = [
      (.none, ""),
      (TextProperties(.red), "Hello"),
      (.none, ""),
      (.none, " World")
    ]
    let normalized = AnsiText.Normalized(segments: segments, optimize: false)
    var chars: [Character] = []
    for item in normalized {
      chars.append(item.character)
    }
    XCTAssertEqual(chars, Array("Hello World"))
  }
  
  func testNormalizedIteratorFirstAndLast() {
    let normalized = AnsiText.plain("Test").normalized
    XCTAssertEqual(normalized.first?.character, "T")
    let chars = Array(normalized)
    XCTAssertEqual(chars.last?.character, "t")
  }
  
  func testNormalizedIteratorEmptyFirstAndLast() {
    let normalized = AnsiText.empty.normalized
    XCTAssertNil(normalized.first)
    let chars = Array(normalized)
    XCTAssertNil(chars.last)
  }
  
  func testNormalizedIteratorFilter() {
    let props = TextProperties(.green)
    let text = AnsiText.annotated(props, "abc123def")
    let normalized = text.normalized
    let digits = normalized.filter { $0.character.isNumber }
    XCTAssertEqual(digits.map { $0.character }, Array("123"))
  }
  
  func testNormalizedIteratorMap() {
    let normalized = AnsiText.plain("xyz").normalized
    let uppercased = normalized.map { $0.character.uppercased() }
    XCTAssertEqual(uppercased, ["X", "Y", "Z"])
  }
  
  func testNormalizedIteratorContains() {
    let normalized = AnsiText.plain("Hello World").normalized
    XCTAssertTrue(normalized.contains(where: { $0.character == "H" }))
    XCTAssertTrue(normalized.contains(where: { $0.character == " " }))
    XCTAssertFalse(normalized.contains(where: { $0.character == "z" }))
  }
  
  func testNormalizedIteratorCount() {
    let normalized = AnsiText.plain("Test").normalized
    var count = 0
    for _ in normalized {
      count += 1
    }
    XCTAssertEqual(count, 4)
    XCTAssertEqual(count, normalized.count)
  }
  
  func testNormalizedIteratorComplexProperties() {
    let props1 = TextProperties(.red, .cyan, .bold)
    let props2 = TextProperties(.blue, .magenta, .underline)
    let segments: [(TextProperties, String)] = [
      (props1, "First"),
      (.none, " "),
      (props2, "Second"),
      (props1, " Third")
    ]
    let normalized = AnsiText.Normalized(segments: segments)
    var result = ""
    var i = 0
    for item in normalized {
      result.append(item.character)
      i += 1
    }
    XCTAssertEqual(i, 18)
    XCTAssertEqual(result, "First Second Third")
  }
  
  func testIteratorCountMatchesProperty() {
    let text: AnsiText = "Hello \("World", properties: TextProperties(.yellow))"
    
    // Count using iterator
    var iteratorCount = 0
    for _ in text {
      iteratorCount += 1
    }
    
    // Count using property
    let propertyCount = text.count
    
    XCTAssertEqual(iteratorCount, propertyCount)
    
    // Same for normalized
    let normalized = text.normalized
    var normalizedIteratorCount = 0
    for _ in normalized {
      normalizedIteratorCount += 1
    }
    
    XCTAssertEqual(normalizedIteratorCount, normalized.count)
    XCTAssertEqual(normalizedIteratorCount, propertyCount)
  }
  
  static let allTests = [
    // Basic Construction
    ("testPlainTextCreation", testPlainTextCreation),
    ("testEmptyText", testEmptyText),
    ("testStringLiteralConformance", testStringLiteralConformance),
    ("testRepeatingCharacter", testRepeatingCharacter),
    ("testRepeatingCharacterWithProperties", testRepeatingCharacterWithProperties),
    
    // Segmented Text
    ("testSegmentedTextCreation", testSegmentedTextCreation),
    ("testSegmentedCount", testSegmentedCount),
    ("testEmptySegments", testEmptySegments),
    
    // Annotated Text
    ("testAnnotatedTextSingleString", testAnnotatedTextSingleString),
    ("testAnnotatedTextMultipleStrings", testAnnotatedTextMultipleStrings),
    ("testAnnotatedTextNoStrings", testAnnotatedTextNoStrings),
    ("testAnnotatedTextWithAnsiText", testAnnotatedTextWithAnsiText),
    ("testNestedAnnotations", testNestedAnnotations),
    
    // String Interpolation
    ("testStringInterpolationPlain", testStringInterpolationPlain),
    ("testStringInterpolationWithProperties", testStringInterpolationWithProperties),
    ("testStringInterpolationWithAnsiText", testStringInterpolationWithAnsiText),
    ("testStringInterpolationWithAny", testStringInterpolationWithAny),
    
    // Normalization
    ("testNormalizedPlain", testNormalizedPlain),
    ("testNormalizedAnnotated", testNormalizedAnnotated),
    ("testNormalizedSegmented", testNormalizedSegmented),
    ("testNormalizedOptimization", testNormalizedOptimization),
    ("testNormalizedEmptySegmentsRemoved", testNormalizedEmptySegmentsRemoved),
    ("testNormalizedTextConversion", testNormalizedTextConversion),
    
    // Tokenization
    ("testTokenizeSingleWord", testTokenizeSingleWord),
    ("testTokenizeMultipleWords", testTokenizeMultipleWords),
    ("testTokenizeWithMultipleSpaces", testTokenizeWithMultipleSpaces),
    ("testTokenizeWithTabs", testTokenizeWithTabs),
    ("testTokenizeEmptyString", testTokenizeEmptyString),
    ("testTokenizePreservesProperties", testTokenizePreservesProperties),
    
    // Split
    ("testSplitBySeparator", testSplitBySeparator),
    ("testSplitWithEmptyParts", testSplitWithEmptyParts),
    ("testSplitPreservesProperties", testSplitPreservesProperties),
    
    // Array Joining
    ("testJoinAnsiTextArrayWithStringSeparator", testJoinAnsiTextArrayWithStringSeparator),
    ("testJoinAnsiTextArrayEmptyArray", testJoinAnsiTextArrayEmptyArray),
    ("testJoinAnsiTextArraySingleElement", testJoinAnsiTextArraySingleElement),
    ("testJoinAnsiTextArrayWithAnsiSeparator", testJoinAnsiTextArrayWithAnsiSeparator),
    ("testJoinNormalizedArrayWithStringSeparator", testJoinNormalizedArrayWithStringSeparator),
    ("testJoinNormalizedArrayWithAnsiSeparator", testJoinNormalizedArrayWithAnsiSeparator),
    ("testJoinNormalizedArrayPropertiesInferred", testJoinNormalizedArrayPropertiesInferred),
    
    // Alignment
    ("testJoinedWithMaxWidthLeftAlign", testJoinedWithMaxWidthLeftAlign),
    ("testJoinedWithMaxWidthRightAlign", testJoinedWithMaxWidthRightAlign),
    ("testJoinedWithMaxWidthCenterAlign", testJoinedWithMaxWidthCenterAlign),
    ("testJoinedWithMaxWidthWrapping", testJoinedWithMaxWidthWrapping),
    ("testJoinedWithNilSeparators", testJoinedWithNilSeparators),
    ("testJoinedWithFillProperties", testJoinedWithFillProperties),
    
    // Complex Integration
    ("testComplexNestedStructure", testComplexNestedStructure),
    ("testNormalizedCountMatchesOriginal", testNormalizedCountMatchesOriginal),
    ("testRoundTripNormalization", testRoundTripNormalization),
    ("testEmptySegmentsInJoin", testEmptySegmentsInJoin),
    ("testPropertiesMerging", testPropertiesMerging),
    
    // AnsiText Iterator Tests
    ("testAnsiTextIteratorPlain", testAnsiTextIteratorPlain),
    ("testAnsiTextIteratorEmpty", testAnsiTextIteratorEmpty),
    ("testAnsiTextIteratorAnnotated", testAnsiTextIteratorAnnotated),
    ("testAnsiTextIteratorSegmented", testAnsiTextIteratorSegmented),
    ("testAnsiTextIteratorComplex", testAnsiTextIteratorComplex),
    ("testAnsiTextIteratorFirstAndLast", testAnsiTextIteratorFirstAndLast),
    ("testAnsiTextIteratorEmptyFirstAndLast", testAnsiTextIteratorEmptyFirstAndLast),
    ("testAnsiTextIteratorFilter", testAnsiTextIteratorFilter),
    ("testAnsiTextIteratorMap", testAnsiTextIteratorMap),
    ("testAnsiTextIteratorContains", testAnsiTextIteratorContains),
    ("testAnsiTextIteratorCount", testAnsiTextIteratorCount),
    
    // Normalized Iterator Tests
    ("testNormalizedIteratorSingleSegment", testNormalizedIteratorSingleSegment),
    ("testNormalizedIteratorEmpty", testNormalizedIteratorEmpty),
    ("testNormalizedIteratorMultipleSegments", testNormalizedIteratorMultipleSegments),
    ("testNormalizedIteratorEmptySegments", testNormalizedIteratorEmptySegments),
    ("testNormalizedIteratorFirstAndLast", testNormalizedIteratorFirstAndLast),
    ("testNormalizedIteratorEmptyFirstAndLast", testNormalizedIteratorEmptyFirstAndLast),
    ("testNormalizedIteratorFilter", testNormalizedIteratorFilter),
    ("testNormalizedIteratorMap", testNormalizedIteratorMap),
    ("testNormalizedIteratorContains", testNormalizedIteratorContains),
    ("testNormalizedIteratorCount", testNormalizedIteratorCount),
    ("testNormalizedIteratorComplexProperties", testNormalizedIteratorComplexProperties),
    ("testIteratorCountMatchesProperty", testIteratorCountMatchesProperty),
  ]
}
