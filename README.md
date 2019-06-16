# Swift CommandLineKit

[![Platform: macOS](https://img.shields.io/badge/Platform-macOS-blue.svg?style=flat)](https://developer.apple.com/osx/)
[![Platform: Linux](https://img.shields.io/badge/Platform-Linux-blue.svg?style=flat)](https://www.ubuntu.com/)
[![Language: Swift 5](https://img.shields.io/badge/Language-Swift%205-green.svg?style=flat)](https://developer.apple.com/swift/)
[![IDE: Xcode 10.2](https://img.shields.io/badge/IDE-Xcode%2010.2-orange.svg?style=flat)](https://developer.apple.com/xcode/)
[![Carthage: compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![License: BSD](https://img.shields.io/badge/License-BSD-lightgrey.svg?style=flat)](https://developers.google.com/open-source/licenses/bsd)

## Overview

This is a library supporting the development of command-line tools in
the programming language Swift on macOS. It also compiles under Linux.
The library provides the following functionality:

   - Management of command-line arguments,
   - Usage of escape sequences on terminals, and
   - Reading strings on terminals using a lineread-inspired implementation
     based on the library [Linenoise-Swift](https://github.com/andybest/linenoise-swift),
     but supporting unicode input, multiple lines, and styled text.

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

### Example

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
let heapSize   = flags.int("h", "heapsize",
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

## Text style and colors

CommandLineKit provides a
[TextProperties](https://github.com/objecthub/swift-commandlinekit/blob/master/Sources/CommandLineKit/TextProperties.swift)
structure for bundling a text color, a background color, and a text style in a single object. Text properties can be
merged with the `with(:)` functions and applied to a string with the `apply(to:)` function.

Individual enumerations for
[TextColor](https://github.com/objecthub/swift-commandlinekit/blob/master/Sources/CommandLineKit/TextColor.swift),
[BackgroundColor](https://github.com/objecthub/swift-commandlinekit/blob/master/Sources/CommandLineKit/BackgroundColor.swift), and
[TextStyle](https://github.com/objecthub/swift-commandlinekit/blob/master/Sources/CommandLineKit/TextStyle.swift)
define the individual properties.

## Reading strings

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

## Requirements

- [Xcode 10.2](https://developer.apple.com/xcode/)
- [Swift 5](https://developer.apple.com/swift/)
- [Carthage](https://github.com/Carthage/Carthage)
- [Swift Package Manager](https://swift.org/package-manager/)
