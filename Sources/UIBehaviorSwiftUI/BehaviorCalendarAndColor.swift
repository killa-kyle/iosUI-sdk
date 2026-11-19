import SwiftUI
import UIBehaviorCore

#if canImport(UIKit)
  import UIKit
#elseif canImport(AppKit)
  import AppKit
#endif

public struct BehaviorCalendar: View {
  @Binding private var model: CalendarSelection
  private let firstWeekday: Int
  @FocusState private var focused: CalendarDate?
  public init(
    _ model: Binding<CalendarSelection>, firstWeekday: Int = Calendar.current.firstWeekday
  ) {
    _model = model
    self.firstWeekday = firstWeekday
  }
  public var body: some View {
    VStack(spacing: 8) {
      HStack {
        Button("Previous month", systemImage: "chevron.left") { model.page(months: -1) }
          .labelStyle(.iconOnly).disabled(model.visibleMonth.addingMonths(-1) == nil)
        Spacer()
        Text(
          "\(DateFormatter().monthSymbols[model.visibleMonth.month-1]) \(String(model.visibleMonth.year))"
        )
        .accessibilityAddTraits(.isHeader)
        Spacer()
        Button("Next month", systemImage: "chevron.right") { model.page(months: 1) }
          .labelStyle(.iconOnly).disabled(model.visibleMonth.addingMonths(1) == nil)
      }.frame(minHeight: 44)
      LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
        ForEach(Array(model.grid(firstWeekday: firstWeekday).enumerated()), id: \.offset) {
          _, date in
          if let date {
            Button {
              model.select(date)
            } label: {
              Text(String(date.day)).frame(maxWidth: .infinity, minHeight: 44)
                .background(
                  (model.selected?.contains(date) ?? false)
                    ? Color.accentColor.opacity(0.2) : .clear,
                  in: RoundedRectangle(cornerRadius: 8))
            }.buttonStyle(.plain).disabled(!model.isEnabled(date))
              .focused($focused, equals: date)
              .opacity(date.month == model.visibleMonth.month ? 1 : 0.5)
              .accessibilityLabel(date.description)
              .accessibilityValue(model.selected?.contains(date) == true ? "Selected" : "")
              .accessibilityIdentifier("calendar-" + date.description)
          } else {
            Color.clear.frame(height: 44)
          }
        }
      }
    }
    .onChange(of: model.focused) { _, date in focused = date }
    .onChange(of: focused) { _, date in if let date { model.focus(date) } }
    .onKeyPress(.leftArrow) {
      model.moveFocus(days: -1)
      return .handled
    }
    .onKeyPress(.rightArrow) {
      model.moveFocus(days: 1)
      return .handled
    }
    .onKeyPress(.upArrow) {
      model.moveFocus(days: -7)
      return .handled
    }
    .onKeyPress(.downArrow) {
      model.moveFocus(days: 7)
      return .handled
    }
    .onKeyPress(.space) {
      model.select(model.focused)
      return .handled
    }
  }
}

public struct BehaviorColorPicker: View {
  @Binding private var value: ColorValue
  private let title: String
  public init(_ title: String = "Color", value: Binding<ColorValue>) {
    self.title = title
    _value = value
  }
  public var body: some View {
    ColorPicker(
      title,
      selection: Binding(
        get: {
          Color(.sRGB, red: value.red, green: value.green, blue: value.blue, opacity: value.alpha)
        },
        set: { color in
          #if canImport(UIKit)
            var r: CGFloat = 0
            var g: CGFloat = 0
            var b: CGFloat = 0
            var a: CGFloat = 0
            if UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a) {
              value = ColorValue(
                red: Double(r), green: Double(g), blue: Double(b), alpha: Double(a))
            }
          #elseif canImport(AppKit)
            if let c = NSColor(color).usingColorSpace(.sRGB) {
              value = ColorValue(
                red: c.redComponent, green: c.greenComponent, blue: c.blueComponent,
                alpha: c.alphaComponent)
            }
          #endif
        }), supportsOpacity: true
    )
    .accessibilityValue(value.hex(includeAlpha: true))
  }
}
