import Foundation

public enum DateBehaviorError: Error { case invalidDate, invalidWeekday }

/// A Gregorian civil day, independent of time zones and daylight-saving changes.
public struct CalendarDate: Hashable, Comparable, Codable, Sendable, CustomStringConvertible {
  public let year: Int
  public let month: Int
  public let day: Int
  public init(year: Int, month: Int, day: Int) throws {
    guard (1...9999).contains(year), (1...12).contains(month),
      (1...Self.daysInMonth(year: year, month: month)).contains(day)
    else { throw DateBehaviorError.invalidDate }
    self.year = year
    self.month = month
    self.day = day
  }
  public init(_ iso: String) throws {
    let pieces = iso.split(separator: "-", omittingEmptySubsequences: false)
    guard pieces.count == 3, pieces[0].count == 4, pieces[1].count == 2,
      pieces[2].count == 2, let y = Int(pieces[0]), let m = Int(pieces[1]),
      let d = Int(pieces[2]), iso.allSatisfy({ $0.isASCII && ($0.isNumber || $0 == "-") })
    else { throw DateBehaviorError.invalidDate }
    try self.init(year: y, month: m, day: d)
  }
  public var description: String { String(format: "%04d-%02d-%02d", year, month, day) }
  public static func daysInMonth(year: Int, month: Int) -> Int {
    guard (1...12).contains(month) else { return 0 }
    return [
      31, year % 4 == 0 && (year % 100 != 0 || year % 400 == 0) ? 29 : 28,
      31, 30, 31, 30, 31, 31, 30, 31, 30, 31,
    ][month - 1]
  }
  private var ordinal: Int {
    let y = year - 1
    return 365 * y + y / 4 - y / 100 + y / 400
      + (1..<month).reduce(0) { $0 + Self.daysInMonth(year: year, month: $1) } + day - 1
  }
  /// Sunday = 1, Monday = 2, matching Foundation Calendar.
  public var weekday: Int { (ordinal + 1) % 7 + 1 }
  public static func < (a: Self, b: Self) -> Bool { a.ordinal < b.ordinal }
  public func addingDays(_ amount: Int) -> Self? {
    let (n, overflow) = ordinal.addingReportingOverflow(amount)
    guard !overflow, (0...3_652_058).contains(n) else { return nil }
    var low = 1
    var high = 9999
    while low < high {
      let mid = (low + high + 1) / 2
      if (try! Self(year: mid, month: 1, day: 1)).ordinal <= n { low = mid } else { high = mid - 1 }
    }
    var remainder = n - (try! Self(year: low, month: 1, day: 1)).ordinal
    var m = 1
    while remainder >= Self.daysInMonth(year: low, month: m) {
      remainder -= Self.daysInMonth(year: low, month: m)
      m += 1
    }
    return try? Self(year: low, month: m, day: remainder + 1)
  }
  public func addingMonths(_ amount: Int) -> Self? {
    let (index, overflow) = ((year - 1) * 12 + month - 1).addingReportingOverflow(amount)
    guard !overflow, (0..<9999 * 12).contains(index) else { return nil }
    let y = index / 12 + 1
    let m = index % 12 + 1
    return try? Self(year: y, month: m, day: min(day, Self.daysInMonth(year: y, month: m)))
  }
  public init(from decoder: Decoder) throws {
    let c = try decoder.singleValueContainer()
    try self.init(c.decode(String.self))
  }
  public func encode(to encoder: Encoder) throws {
    var c = encoder.singleValueContainer()
    try c.encode(description)
  }
}

public struct CalendarSelection: Sendable, Equatable {
  public enum Mode: Sendable { case single, range }
  public let mode: Mode
  public var bounds: ClosedRange<CalendarDate>?
  public var disabled: Set<CalendarDate>
  public private(set) var visibleMonth: CalendarDate
  public private(set) var focused: CalendarDate
  public private(set) var selected: ClosedRange<CalendarDate>?
  private var anchor: CalendarDate?
  public init(
    month: CalendarDate, mode: Mode = .single,
    bounds: ClosedRange<CalendarDate>? = nil, disabled: Set<CalendarDate> = []
  ) {
    self.mode = mode
    self.bounds = bounds
    self.disabled = disabled
    focused = month
    visibleMonth = try! CalendarDate(year: month.year, month: month.month, day: 1)
  }
  public func isEnabled(_ date: CalendarDate) -> Bool {
    !disabled.contains(date) && (bounds?.contains(date) ?? true)
  }
  @discardableResult public mutating func select(_ date: CalendarDate) -> Bool {
    guard isEnabled(date) else { return false }
    if mode == .range, let start = anchor, isEnabled(start) {
      let range = min(start, date)...max(start, date)
      guard !disabled.contains(where: { range.contains($0) }) else { return false }
      selected = range
      anchor = nil
    } else {
      selected = date...date
      anchor = mode == .range ? date : nil
    }
    focus(date)
    return true
  }
  public mutating func focus(_ date: CalendarDate) {
    guard isEnabled(date) else { return }
    focused = date
    visibleMonth = try! CalendarDate(year: date.year, month: date.month, day: 1)
  }
  public mutating func moveFocus(days: Int) {
    guard days != 0 else { return }
    var candidate = focused.addingDays(days)
    if let bounds, let date = candidate {
      if days > 0 && date < bounds.lowerBound { candidate = bounds.lowerBound }
      if days < 0 && date > bounds.upperBound { candidate = bounds.upperBound }
    }
    for _ in 0...disabled.count {
      guard let date = candidate, bounds?.contains(date) ?? true else { return }
      if isEnabled(date) {
        focused = date
        visibleMonth = try! CalendarDate(year: date.year, month: date.month, day: 1)
        return
      }
      candidate = date.addingDays(days)
    }
  }
  public mutating func page(months: Int) {
    guard let date = visibleMonth.addingMonths(months) else { return }
    visibleMonth = date
  }
  public func grid(firstWeekday: Int = 1) -> [CalendarDate?] {
    guard (1...7).contains(firstWeekday) else { return [] }
    let offset = (visibleMonth.weekday - firstWeekday + 7) % 7
    return (0..<42).map { visibleMonth.addingDays($0 - offset) }
  }
}
