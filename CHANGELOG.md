# Changelog

# Unreleased
- `LineReader` positions the cursor based on terminal column widths instead of character counts:
  wide characters (e.g. CJK, emoji) count as two columns and zero-width characters (e.g.
  combining marks) as none, both in the input and the prompt. A wide character which does not
  fit into the remainder of a row is wrapped to the next row, as terminals do
- ANSI escape sequences contained in the prompt passed to `LineReader.readLine` (e.g. colors
  and text styles) no longer count towards the width of the prompt
- Hints are hidden based on the display width of the prompt, input, and hint

# 1.1.3 (2026-10-24)
- Repeated arguments can be declared with `greedy: false`. Every occurrence of such a flag takes
  exactly one parameter and multiple parameters are provided by repeating the flag, e.g.
  `-r dir1 -r dir2`. Parameters following the flag, such as a program name, are not consumed by
  the flag, and a missing parameter is reported as an error. By default, repeated arguments are
  greedy and consume all arguments up to the next flag.
- New terminator `--` for the parameters of greedy repeated arguments, e.g.
  `-f a b -- -l c d -- program`. In contrast to the terminator `---`, it does not end the parsing
  of flags: flags following it are parsed as usual, and it can be used with several repeated
  arguments. `--` is ignored if it does not follow a repeated argument.
- New property `Argument.greedy`; new parameter `greedy` for the initializers of `Argument` and
  `RepeatedArgument`, for `Flags.argument`, `Flags.arguments`, `Flags.strings`, `Flags.ints`,
  `Flags.doubles` and `Flags.enums`, and for the `@CommandArguments` property wrapper

# 1.1.2 (2026-10-08)
- Fixed crashes when joining `AnsiText.Normalized`/`AnsiText` values without segments
- Fixed line widths calculated by `joined(separator:maxWidth:)` for lines starting with empty texts
- `joined(separator:maxWidth:)` takes the actual width of the separator into account
- `AnsiText.Normalized` values without characters consistently have no segments, e.g.
  `Normalized("") == Normalized(segments: [])`
- Fixed `AnsiText.Normalized.apply(properties:override:)` to merge adjacent segments with
  identical properties
- Fixed documentation of `AnsiText.terminalDisplayWidth`

# 1.1.1 (2026-06-01)
- Provide more constructors for `TextColor` and `BackgroundColor`

# 1.1 (2026-05-15)
- Support determining the size of ANSI terminals via `Terminal.size`
- Allow setting the cursor style
- Provide a representation of styled text via `AnsiText`
- Comprehensive formatting support for styled text

# 1.0 (2023-08-23)
- Provide declarative API for defining command-line tools
- Improve color-detection for terminals
- Migrate framework to Xcode 14

# 0.3.5 (2023-01-29)
- Be more clever about detecting color terminals
- Migrate project to Xcode 14.2

## 0.3.4 (2021-05-12)
- Minor bug fixes
- Migrated project to Xcode 12.5

## 0.3.3 (2020-10-04)
- Ported code to Swift 5.3
- Migrated project to Xcode 12.0

## 0.3.2 (2020-02-01)
- Fixed line reader to handle buffered output
- Migrated project to Xcode 11.3

## 0.3.1 (2019-09-23)
- Migrated project to Xcode 11.0
- Ported code to Swift 5.1

## 0.3 (2019-03-30)
- Migrated library to Xcode 10.2
- Ported code to Swift 5

## 0.2 (2018-06-10)
- Bug fixes
- Support of usage descriptions
- Initial documentation

## 0.1 (2018-05-14)
- Initial version
