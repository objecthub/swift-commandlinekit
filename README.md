# Swift CommandLineKit

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fobjecthub%2Fswift-commandlinekit%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/objecthub/swift-commandlinekit) [![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fobjecthub%2Fswift-commandlinekit%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/objecthub/swift-commandlinekit) [![IDE: Xcode 16](https://img.shields.io/badge/IDE-Xcode%2016-blue.svg?style=flat)](https://developer.apple.com/xcode/) [![Package managers: SwiftPM, Carthage](https://img.shields.io/badge/Package%20managers-SwiftPM,%20Carthage-green.svg?style=flat)](https://github.com/Carthage/Carthage) [![License: Apache](http://img.shields.io/badge/License-Apache-lightgrey.svg?style=flat)](https://raw.githubusercontent.com/objecthub/swift-numberkit/master/LICENSE)

This is a library supporting the development of command-line tools in
the programming language Swift on macOS. It also compiles on iOS and Linux.
The library provides the following functionality:

   - Management of command-line arguments,
   - Usage of escape sequences on terminals, e.g. for formatting output on ANSI terminals, and
   - Reading strings on terminals using a lineread-inspired implementation
     based on the library [Linenoise-Swift](https://github.com/andybest/linenoise-swift),
     but supporting unicode input, multiple lines, and styled text.
   - Reading strings on terminals in a secure way hiding user input, e.g. for entering
     passwords, API keys, etc.

<table width="100%">
<tr><th colspan="2">Table of contents</th></tr>
<tr>
<td width="650px" valign="top">
1. &nbsp;<a href="#command-line-arguments">Command-line arguments</a><br />
&nbsp;&nbsp; 1.1 &nbsp;<a href="#basics">Basics</a><br />
&nbsp;&nbsp; 1.2 &nbsp;<a href="#programmatic-api">Programmatic API</a><br />
&nbsp;&nbsp; 1.3 &nbsp;<a href="#declarative-api">Declarative API</a><br />
2. &nbsp;<a href="#styled-output">Styled output</a><br />
&nbsp;&nbsp; 2.1 &nbsp;<a href="#text-style-and-colors">Text style and colors</a><br />
&nbsp;&nbsp; 2.2 &nbsp;<a href="#styled-string-formatting">Styled string formatting</a><br />
</td>
<td width="50%" valign="top">
3. &nbsp;<a href="#reading-strings">Reading strings</a><br />
&nbsp;&nbsp; 3.1 &nbsp;<a href="#readline">Readline</a><br />
&nbsp;&nbsp; 3.2 &nbsp;<a href="#secure-readline">Secure readline</a><br />
4. &nbsp;<a href="#requirements">Requirements</a><br />
5. &nbsp;<a href="#copyright">Copyright</a><br />
</td>
</tr>
</table>

&nbsp;

## Command-line arguments

### Basics

CommandLineKit handles command-line arguments with the following protocol:

   1. A new [Flags](https://github.com/objecthub/swift-commandlinekit/blob/master/Sources/CommandLineKit/Flags.swift)
      object gets created either for the system-provided command-line arguments or for a
      custom sequence of arguments.
   2. For every flag, a [Flag](https://github.com/objecthub/swift-commandlinekit/blob/master/Sources/CommandLineKit/Flag.swift)
       object is being created and registered in the `Flags` object.
   3. Once all flag objects are declared and registered, the command-line gets parsed. After parsing
      is complete, the flag objects can be used to access the extracted options and arguments.

CommandLineKit defines different types of
[Flag](https://github.com/objecthub/swift-commandlinekit/blob/master/Sources/CommandLineKit/Flag.swift)
subclasses for handling _options_ (i.e. flags without
parameters) and _arguments_ (i.e. flags with parameters). Arguments are either _singleton arguments_ (i.e. they
have exactly one value) or they are _repeated arguments_ (i.e. they have many values). Arguments are
parameterized with a type which defines how to parse values. The framework natively supports _int_,
_double_, _string_, and _enum_ types, which means that in practice, just using the built-in flag classes
are almost always sufficient. Nevertheless,
[the framework is extensible](https://github.com/objecthub/swift-commandlinekit/tree/master/Sources/CommandLineKit)
and supports arbitrary argument types.

A flag is identified by a _short name_ character and a _long name_ string. At least one of the two needs to be
defined. For instance, the "help" option could be defined by the short name "h" and the long name "help".
On the command-line, a user could either use `-h` or `--help` to refer to this option; i.e. short names are
prefixed with a single dash, long names are prefixed with a double dash.

An argument is a parameterized flag. The parameters follow directly the flag identifier (typically separated by
a space). For instance, an integer argument with long name "size" could be defined as: `--size 64`. If the
argument is repeated, then multiple parameters may follow the flag identifier, as in this
example: `--size 2 4 8 16`. The sequence is terminated by either the end of the command-line arguments,
another flag, or the terminator "---". All command-line arguments following the terminator are not being parsed
and are returned in the `parameters` field of the `Flags` object.

### Programmatic API

Here is an [example](https://github.com/objecthub/swift-lispkit/blob/master/Sources/LispKitRepl/main.swift)
from the [LispKit](https://github.com/objecthub/swift-lispkit) project. It uses factory methods (like `flags.string`,
`flags.int`, `flags.option`, `flags.strings`, etc.) provided by the
[Flags](https://github.com/objecthub/swift-commandlinekit/blob/master/Sources/CommandLineKit/Flags.swift)
class to create and register individual flags.

```swift
// Create a new flags object for the system-provided command-line arguments
var flags = Flags()

// Define the various flags
let filePaths  = flags.strings("f", "filepath",
                               description: "Adds file path in which programs are searched for.")
let libPaths   = flags.strings("l", "libpath",
                               description: "Adds file path in which libraries are searched for.")
let heapSize   = flags.int("x", "heapsize",
                           description: "Initial capacity of the heap", value: 1000)
let importLibs = flags.strings("i", "import",
                               description: "Imports library automatically after startup.")
let prelude    = flags.string("p", "prelude",
                              description: "Path to prelude file which gets executed after " +
                                           "loading all provided libraries.")
let prompt     = flags.string("r", "prompt",
                              description: "String used as prompt in REPL.", value: "> ")
let quiet      = flags.option("q", "quiet",
                              description: "In quiet mode, optional messages are not printed.")
let help       = flags.option("h", "help",
                              description: "Show description of usage and options of this tools.")

// Parse the command-line arguments and return error message if parsing fails
if let failure = flags.parsingFailure() {
  print(failure)
  exit(1)
}
```

The framework supports printing the supported options via the `Flags.usageDescription` function. For the
command-line flags as defined above, this function returns the following usage description:

```
usage: LispKitRepl [<option> ...] [---] [<program> <arg> ...]
options:
  -f, --filepath <value> ...
      Adds file path in which programs are searched for.
  -l, --libpath <value> ...
      Adds file path in which libraries are searched for.
  -h, --heapsize <value>
      Initial capacity of the heap
  -i, --import <value> ...
      Imports library automatically after startup.
  -p, --prelude <value>
      Path to prelude file which gets executed after loading all provided libraries.
  -r, --prompt <value>
      String used as prompt in REPL.
  -q, --quiet
      In quiet mode, optional messages are not printed.
  -h, --help
      Show description of usage and options of this tools.
```

Command-line tools can inspect whether a flag was set via the `Flag.wasSet` field. For flags with
parameters, the parameters are stored in the `Flag.value` field. The type of this field is dependent on the
flag type. For repeated flags, an array is used.

Here is an example how the flags defined by the code snippet above could be used:

```swift
// If help flag was provided, print usage description and exit tool
if help.wasSet {
  print(flags.usageDescription(usageName: TextStyle.bold.properties.apply(to: "usage:"),
                               synopsis: "[<option> ...] [---] [<program> <arg> ...]",
                               usageStyle: TextProperties.none,
                               optionsName: TextStyle.bold.properties.apply(to: "options:"),
                               flagStyle: TextStyle.italic.properties),
        terminator: "")
  exit(0)
}
...
// Define how optional messages and errors are printed
func printOpt(_ message: String) {
  if !quiet.wasSet {
    print(message)
  }
}
...
// Set heap size (assuming 1234 is the default if the flag is not set)
virtualMachine.setHeapSize(heapSize.value ?? 1234)
...
// Register all file paths
for path in filePaths.value {
  virtualMachine.fileHandler.register(path)
}
...
// Load prelude file if it was provided via flag `prelude`
if let file = prelude.value {
  virtualMachine.load(file)
}
```

### Declarative API

The code below illustrates how to combine the `Command` protocol with property wrappers
declaring the various command-line flags. The whole lifecycle of a command-line tool that
is declared like this will be managed automatically. After flags are being parsed, either
methods `run()` or `fail(with:)` are being called (depending on whether flag parsing
succeeds or fails).

```swift
@main struct LispKitRepl: Command {
  @CommandArguments(short: "f", description: "Adds file path in which programs are searched for.")
  var filePath: [String]
  @CommandArguments(short: "l", description: "Adds file path in which libraries are searched for.")
  var libPaths: [String]
  @CommandArgument(short: "x", description: "Initial capacity of the heap")
  var heapSize: Int = 1234
  ...
  @CommandOption(short: "h", description: "Show description of usage and options of this tools.")
  var help: Bool
  @CommandParameters // Inject the unparsed parameters
  var params: [String]
  @CommandFlags // Inject the flags object
  var flags: Flags
  
  mutating func fail(with reason: String) throws {
    print(reason)
    exit(1)
  }
  
  mutating func run() throws {
    // If help flag was provided, print usage description and exit tool
    if help {
      print(flags.usageDescription(usageName: TextStyle.bold.properties.apply(to: "usage:"),
                                   synopsis: "[<option> ...] [---] [<program> <arg> ...]",
                                   usageStyle: TextProperties.none,
                                   optionsName: TextStyle.bold.properties.apply(to: "options:"),
                                   flagStyle: TextStyle.italic.properties),
            terminator: "")
      exit(0)
    }
    ...
    // Define how optional messages and errors are printed
    func printOpt(_ message: String) {
      if !quiet {
        print(message)
      }
    }
    ...
    // Set heap size
    virtualMachine.setHeapSize(heapSize)
    ...
    // Register all file paths
    for path in filePaths {
      virtualMachine.fileHandler.register(path)
    }
    ...
    // Load prelude file if it was provided via flag `prelude`
    if let file = prelude {
      virtualMachine.load(file)
    }
  }
}
```

## Styled output

### Text style and colors

CommandLineKit provides a
[TextProperties](https://github.com/objecthub/swift-commandlinekit/blob/master/Sources/CommandLineKit/TextProperties.swift)
structure for bundling a text color, a background color, and a text style in a single object. Text properties can be
merged with the `with(:)` methods and applied to a string with the `apply(to:)` method.

Individual enumerations for
[TextColor](https://github.com/objecthub/swift-commandlinekit/blob/master/Sources/CommandLineKit/TextColor.swift),
[BackgroundColor](https://github.com/objecthub/swift-commandlinekit/blob/master/Sources/CommandLineKit/BackgroundColor.swift), and
[TextStyle](https://github.com/objecthub/swift-commandlinekit/blob/master/Sources/CommandLineKit/TextStyle.swift)
define the individual properties.

### Styled string formatting

Using [TextProperties](https://github.com/objecthub/swift-commandlinekit/blob/master/Sources/CommandLineKit/TextProperties.swift)
and its `apply(to:)` method can be used to inject ANSI escape sequences into strings so that they appear formatted on
ANSI terminals. But using this approach directly makes it really difficult to format output, e.g. to center or right-align
content. For this purpose, enum [AnsiText](https://github.com/objecthub/swift-commandlinekit/blob/master/Sources/CommandLineKit/AnsiText.swift) is provided. It bundles strings with `TextProperties`-based styling definitions.
`AnsiText` can be initialized directly from strings and properties can be injected via string interpolation.

`AnsiText` represents styled text as a tree structure with three cases:
- **`plain(String)`**: Unstyled text
- **`segmented([AnsiText])`**: Multiple concatenated text segments
- **`annotated(TextProperties, AnsiText)`**: Text with styling applied

```swift
enum AnsiText: ... {
  case plain(String)
  case segmented([AnsiText])
  indirect case annotated(TextProperties, AnsiText)
  ...
  struct Normalized: ... {
    var segments: [(TextProperties, String)]
    init(segments: [(TextProperties, String)]) { ... }
    init(_ string: String = "", properties: TextProperties = .empty) { ... }
    init(repeating: String, count: Int, properties: TextProperties = .empty) { ... }
    ...
  }
  ...
  // Normalized representation
  var normalized: Normalized { ... }
  // Returns the number of characters (ignoring formatting)
  var count: Int { ... }
  // Returns the width of the output in ANSI terminals
  // (factoring in multi-place unicode characters)
  var terminalDisplayWidth: Int { ... }
}
```

Here are some basic usage examples:

```swift
// Create text using string literals
let text: AnsiText = "Hello, World!"
// Apply styling via string interpolation
let styled: AnsiText = "Error: \("File not found", properties: .init(.red, nil, .bold))"
// Compose complex styled text
let message: AnsiText = .segmented([
  .annotated(.init(.green), "Success: "),
  .plain("Operation completed in "),
  .annotated(.init(.blue, nil, .bold), "1.2s")
])
```

#### AnsiText.Normalized

While `AnsiText` provides a convenient tree-based representation, `AnsiText.Normalized` offers a flattened, optimized form that merges adjacent segments with identical properties. This makes it more efficient for rendering and text manipulation operations:

```swift
let text: AnsiText = "Hello \("World", properties: .init(.red))"
let normalized = text.normalized
// normalized segments: [(.empty, "Hello "), (.red, "World")]
// Normalized provides direct access to segments
for (properties, string) in normalized.segments {
  print("\(string) with \(properties)")
}
// Normalized is a collection and bi-directional sequence
// providing the same access to characters as strings (but with
// text properties injected):
for (properties, ch) in normalized {
  print("`\(ch)` with \(properties)")
}
// Get plain text or encoded output
print(normalized.description) // "Hello World"
print(normalized.encodedString) // "Hello \u{001B}[31mWorld\u{001B}[0m"
```

Key differences between `AnsiText` and `AnsiText.Normalized`:
- **Structure**: `AnsiText` is a hierarchical tree; `Normalized` is a flat array of segments
- **Optimization**: `Normalized` merges adjacent segments with the same properties
- **Performance**: `Normalized` is more efficient for rendering and manipulation
- **Usage**: Use `AnsiText` for construction; convert to `Normalized` for processing

#### Formatting functions

Arrays of `AnsiText`, `AnsiText?`, `AnsiText.Normalized`, and `AnsiText.Normalized?` values support
powerful formatting functions for aligning and wrapping text:

**`justified(maxWidth:align:alignWidth,padCharacter:fill:)`** interprets the array as an array of lines each
represented by one `AnsiText` or `AnsiText.Normalized` value and aligns individual lines to a
specified width. It is using the character count by default to do the alignment. If
`alignWidth` is set to true, the alignment is done by using `terminalDisplayWidth` which factors
in that some unicode characters (e.g. emojis) require multiple places when output in ANSI terminals.

```swift
let lines: [AnsiText] = [
  "Short line",
  "A \("longer red", properties: .red) line",
  .annotated(.italic, "And \("short", properties: .underline) again")
]
// Normalize the lines first
let normalizedLines = lines.map { $0.normalized }
// Left-align with padding
let left = normalizedLines.justified(maxWidth: 20, align: .left)
// Center-align with custom padding
let centered = normalizedLines.justified(maxWidth: 20, align: .center, padCharacter: ".", fill: TextProperties(.grey))
// Right-align factoring in the display width
let right = normalizedLines.justified(maxWidth: 20, align: .right, alignWidth: true)
```

**`joined(separator:maxWidth:align:alignWidth:padCharacter:fill)`** interprets the array as an array
of words each represented by an `AnsiText` or `AnsiText.Normalized` value and combines words with
word wrapping and alignment:

```swift
// Styled text
let text: AnsiText = "The quick \("brown fox", properties: .bold) jumps over the lazy dog"
// Tokenize styled text
let words = text.normalized.tokenize()
// Word-wrap to 15 characters with right alignment
let wrapped = words.joined(separator: " ", maxWidth: 15, align: .right)
// Join the lines and include the ANSI control sequences
let all = wrapped.joined(separator: "\n").encodedString
print(all)
// Output (centered in 15-char field):
//   "The quick brown"
//   " fox jumps over"
//   "   the lazy dog"
```

These formatting functions enable sophisticated terminal output, such as creating aligned tables with
styled cells, wrapped paragraphs, and justified text blocks while preserving all ANSI styling information.

## Reading strings

### Readline

CommandLineKit includes a significantly improved version of the "readline" API originally defined by the library
[Linenoise-Swift](https://github.com/andybest/linenoise-swift). It supports unicode text, multi-line text entry, and
styled text. It supports all the existing features such as _advanced keyboard support_, _history_,
_text completion_, and _hints_.

The following code illustrates the usage of the
[LineReader](https://github.com/objecthub/swift-commandlinekit/blob/master/Sources/CommandLineKit/LineReader.swift) API:

```swift
if let ln = LineReader() {
  ln.setCompletionCallback { currentBuffer in
    let completions = [
      "Hello!",
      "Hello Google",
      "Scheme is awesome!"
    ]
    return completions.filter { $0.hasPrefix(currentBuffer) }
  }
  ln.setHintsCallback { currentBuffer in
    let hints = [
      "Foo",
      "Lorem Ipsum",
      "Scheme is awesome!"
    ]
    let filtered = hints.filter { $0.hasPrefix(currentBuffer) }
    if let hint = filtered.first {
      let hintText = String(hint.dropFirst(currentBuffer.count))
      return (hintText, TextColor.grey.properties)
    } else {
      return nil
    }
  }
  print("Type 'exit' to quit")
  var done = false
  while !done {
    do {
      let output = try ln.readLine(prompt: "> ",
                                   maxCount: 200,
                                   strippingNewline: true,
                                   promptProperties: TextProperties(.green, nil, .bold),
                                   readProperties: TextProperties(.blue, nil),
                                   parenProperties: TextProperties(.red, nil, .bold))
      print("Entered: \(output)")
      ln.addHistory(output)
      if output == "exit" {
        break
      }
    } catch LineReaderError.CTRLC {
      print("\nCaptured CTRL+C. Quitting.")
      done = true
    } catch {
      print(error)
    }
  }
}
```

### Secure readline



## Requirements

- [Xcode 26](https://developer.apple.com/xcode/)
- [Swift 6](https://developer.apple.com/swift/)
- [Carthage](https://github.com/Carthage/Carthage)
- [Swift Package Manager](https://swift.org/package-manager/)

## Copyright

Author: Matthias Zenger (<matthias@objecthub.com>)  
Copyright © 2018-2025 Google LLC.  
Copyright © 2026 Matthias Zenger  
_Please note: This is not an official Google product._
