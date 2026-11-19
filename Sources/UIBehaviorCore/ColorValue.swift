import Foundation

public struct ColorValue: Hashable, Sendable, Codable {
  private enum CodingKeys: String, CodingKey { case red, green, blue, alpha }
  public let red: Double
  public let green: Double
  public let blue: Double
  public let alpha: Double
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let r = try container.decode(Double.self, forKey: .red)
    let g = try container.decode(Double.self, forKey: .green)
    let b = try container.decode(Double.self, forKey: .blue)
    let a = try container.decode(Double.self, forKey: .alpha)
    guard [r, g, b, a].allSatisfy(\.isFinite) else {
      throw DecodingError.dataCorrupted(
        .init(codingPath: decoder.codingPath, debugDescription: "Color channels must be finite"))
    }
    self.init(red: r, green: g, blue: b, alpha: a)
  }
  public init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
    precondition([red, green, blue, alpha].allSatisfy(\.isFinite))
    self.red = min(1, max(0, red))
    self.green = min(1, max(0, green))
    self.blue = min(1, max(0, blue))
    self.alpha = min(1, max(0, alpha))
  }
  public init?(hex: String) {
    var s = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
    guard [3, 4, 6, 8].contains(s.count), s.allSatisfy(\.isHexDigit) else { return nil }
    if s.count < 5 { s = s.map { String(repeating: String($0), count: 2) }.joined() }
    guard let n = UInt64(s, radix: 16) else { return nil }
    let hasAlpha = s.count == 8
    let rgb = hasAlpha ? n >> 8 : n
    self.init(
      red: Double((rgb >> 16) & 255) / 255, green: Double((rgb >> 8) & 255) / 255,
      blue: Double(rgb & 255) / 255, alpha: hasAlpha ? Double(n & 255) / 255 : 1)
  }
  public init(hue: Double, saturation: Double, brightness: Double, alpha: Double = 1) {
    precondition([hue, saturation, brightness, alpha].allSatisfy(\.isFinite))
    let h = (hue - floor(hue)) * 6
    let s = min(1, max(0, saturation))
    let v = min(1, max(0, brightness))
    let c = v * s
    let x = c * (1 - abs(h.truncatingRemainder(dividingBy: 2) - 1))
    let m = v - c
    let rgb: (Double, Double, Double)
    switch Int(h) {
    case 0: rgb = (c, x, 0)
    case 1: rgb = (x, c, 0)
    case 2: rgb = (0, c, x)
    case 3: rgb = (0, x, c)
    case 4: rgb = (x, 0, c)
    default: rgb = (c, 0, x)
    }
    self.init(red: rgb.0 + m, green: rgb.1 + m, blue: rgb.2 + m, alpha: alpha)
  }
  public var hsba: (hue: Double, saturation: Double, brightness: Double, alpha: Double) {
    let hi = max(red, green, blue)
    let lo = min(red, green, blue)
    let d = hi - lo
    var h = 0.0
    if d > 0 {
      if hi == red {
        h = ((green - blue) / d).truncatingRemainder(dividingBy: 6)
      } else if hi == green {
        h = (blue - red) / d + 2
      } else {
        h = (red - green) / d + 4
      }
      h /= 6
      if h < 0 { h += 1 }
    }
    return (h, hi == 0 ? 0 : d / hi, hi, alpha)
  }
  public func hex(includeAlpha: Bool = false) -> String {
    let values = [red, green, blue] + (includeAlpha ? [alpha] : [])
    return "#" + values.map { String(format: "%02X", Int(($0 * 255).rounded())) }.joined()
  }
  public func composited(over background: Self) -> Self {
    let a = alpha + background.alpha * (1 - alpha)
    guard a > 0 else { return Self(red: 0, green: 0, blue: 0, alpha: 0) }
    func channel(_ f: Double, _ b: Double) -> Double {
      (f * alpha + b * background.alpha * (1 - alpha)) / a
    }
    return Self(
      red: channel(red, background.red), green: channel(green, background.green),
      blue: channel(blue, background.blue), alpha: a)
  }
  /// Composite translucent colors onto an opaque backdrop before measuring contrast.
  public func contrast(against other: Self, backdrop: Self = Self(red: 1, green: 1, blue: 1))
    -> Double
  {
    func luminance(_ c: Self) -> Double {
      func linear(_ v: Double) -> Double {
        v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
      }
      return linear(c.red) * 0.2126 + linear(c.green) * 0.7152 + linear(c.blue) * 0.0722
    }
    let bg = other.composited(over: backdrop)
    let fg = composited(over: bg)
    let a = luminance(fg)
    let b = luminance(bg)
    return (max(a, b) + 0.05) / (min(a, b) + 0.05)
  }
}
