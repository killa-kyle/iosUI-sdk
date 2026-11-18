import Foundation

public enum RichTextStyle: Hashable, Sendable, Codable {
  case bold, italic, underline
  case link(String)
}
public struct RichTextRun: Equatable, Sendable, Codable {
  public var location: Int
  public var length: Int
  public var style: RichTextStyle
  public init(location: Int, length: Int, style: RichTextStyle) {
    self.location = location
    self.length = length
    self.style = style
  }
}
/// Native UTF-16 ranges, compatible with TextKit/NSAttributedString. No HTML evaluation.
public struct RichTextDocument: Sendable, Equatable {
  private static func valid(_ range: NSRange, in text: String) -> Bool {
    let units = Array(text.utf16)
    let (end, overflow) = range.location.addingReportingOverflow(range.length)
    guard !overflow, range.location >= 0, range.length >= 0, end <= units.count else {
      return false
    }
    func boundary(_ index: Int) -> Bool {
      index == 0 || index == units.count || !(0xDC00...0xDFFF).contains(units[index])
    }
    return boundary(range.location) && boundary(end)
  }
  public private(set) var text: String
  public private(set) var runs: [RichTextRun]
  public private(set) var selection: NSRange
  public private(set) var typingStyles: Set<RichTextStyle> = []
  public init(
    _ text: String = "", runs: [RichTextRun] = [],
    selection: NSRange = NSRange(location: 0, length: 0)
  ) {
    self.text = text
    self.runs = runs.filter {
      Self.valid(NSRange(location: $0.location, length: $0.length), in: text) && $0.length > 0
    }
    self.selection = Self.valid(selection, in: text) ? selection : NSRange(location: 0, length: 0)
  }
  @discardableResult public mutating func select(_ range: NSRange) -> Bool {
    guard Self.valid(range, in: text) else { return false }
    selection = range
    let offset = range.location > 0 && range.length == 0 ? range.location - 1 : range.location
    typingStyles = Set(
      runs.filter { $0.location <= offset && $0.location + $0.length > offset }.map(\.style))
    return true
  }
  public mutating func toggle(_ style: RichTextStyle) {
    let range = selection
    guard range.length > 0 else {
      if typingStyles.remove(style) == nil { typingStyles.insert(style) }
      return
    }
    let end = range.location + range.length
    let matching = runs.filter { $0.style == style }.sorted { $0.location < $1.location }
    var coveredTo = range.location
    for run in matching where run.location <= coveredTo && run.location + run.length > coveredTo {
      coveredTo = run.location + run.length
    }
    var remaining: [RichTextRun] = []
    for run in runs {
      guard run.style == style, run.location < end, run.location + run.length > range.location
      else {
        remaining.append(run)
        continue
      }
      if run.location < range.location {
        remaining.append(
          RichTextRun(location: run.location, length: range.location - run.location, style: style))
      }
      if run.location + run.length > end {
        remaining.append(
          RichTextRun(location: end, length: run.location + run.length - end, style: style))
      }
    }
    if coveredTo < end {
      remaining.append(RichTextRun(location: range.location, length: range.length, style: style))
    }
    runs = remaining
  }
  @discardableResult public mutating func replaceSelection(with replacement: String) -> Bool {
    guard let range = Range(selection, in: text) else { return false }
    let start = selection.location
    let end = start + selection.length
    let inserted = replacement.utf16.count
    let delta = inserted - selection.length
    var result: [RichTextRun] = []
    for run in runs {
      let runEnd = run.location + run.length
      if runEnd <= start {
        result.append(run)
      } else if run.location >= end {
        result.append(
          RichTextRun(location: run.location + delta, length: run.length, style: run.style))
      } else {
        if run.location < start {
          result.append(
            RichTextRun(location: run.location, length: start - run.location, style: run.style))
        }
        if runEnd > end {
          result.append(
            RichTextRun(location: start + inserted, length: runEnd - end, style: run.style))
        }
      }
    }
    for style in typingStyles where inserted > 0 {
      result.append(RichTextRun(location: start, length: inserted, style: style))
    }
    text.replaceSubrange(range, with: replacement)
    runs = result
    selection = NSRange(location: start + inserted, length: 0)
    return true
  }
}
