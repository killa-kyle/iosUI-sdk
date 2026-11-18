#if canImport(UIKit)
  import UIKit
  import SwiftUI
  import UIBehaviorCore
  import UIBehaviorSwiftUI
  import UIBehaviorTextKit

  public typealias BehaviorRichTextView = BehaviorTextView

  @MainActor private final class BehaviorStore<Value>: ObservableObject {
    @Published var value: Value
    init(_ value: Value) { self.value = value }
  }
  private struct HostedBehavior<Value, Content: View>: View {
    @ObservedObject var store: BehaviorStore<Value>
    let content: (Binding<Value>) -> Content
    let onChange: (Value) -> Void
    var body: some View {
      content(
        Binding(
          get: { store.value },
          set: {
            store.value = $0
            onChange($0)
          }))
    }
  }
  /// Embed any production behavior adapter through standard UIKit containment.
  /// The state remains readable/writable from UIKit; programmatic writes do not emit user callbacks.
  @MainActor public final class BehaviorController<Value, Content: View>: UIViewController {
    private let store: BehaviorStore<Value>
    private let render: (Binding<Value>) -> Content
    private let onChange: (Value) -> Void
    private var hosting: UIHostingController<HostedBehavior<Value, Content>>?
    public var state: Value {
      get { store.value }
      set { store.value = newValue }
    }
    public init(
      state: Value, onChange: @escaping (Value) -> Void = { _ in },
      @ViewBuilder content: @escaping (Binding<Value>) -> Content
    ) {
      store = BehaviorStore(state)
      render = content
      self.onChange = onChange
      super.init(nibName: nil, bundle: nil)
    }
    public required init?(coder: NSCoder) { nil }
    public override func viewDidLoad() {
      super.viewDidLoad()
      let host = UIHostingController(
        rootView: HostedBehavior(store: store, content: render, onChange: onChange))
      addChild(host)
      host.view.translatesAutoresizingMaskIntoConstraints = false
      view.addSubview(host.view)
      NSLayoutConstraint.activate([
        host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        host.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
        host.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
      ])
      host.didMove(toParent: self)
      hosting = host
    }
  }

  @MainActor public enum BehaviorUIKit {
    public static func calendar(
      _ state: CalendarSelection, onChange: @escaping (CalendarSelection) -> Void = { _ in }
    )
      -> BehaviorController<CalendarSelection, BehaviorCalendar>
    {
      BehaviorController(state: state, onChange: onChange) { BehaviorCalendar($0) }
    }
    public static func color(
      _ state: ColorValue, onChange: @escaping (ColorValue) -> Void = { _ in }
    )
      -> BehaviorController<ColorValue, BehaviorColorPicker>
    {
      BehaviorController(state: state, onChange: onChange) { BehaviorColorPicker(value: $0) }
    }
    public static func grid(
      _ state: GridNavigation, label: @escaping (GridCell) -> String,
      onChange: @escaping (GridNavigation) -> Void = { _ in }
    ) -> BehaviorController<GridNavigation, BehaviorGrid> {
      BehaviorController(state: state, onChange: onChange) { BehaviorGrid($0, label: label) }
    }
    public static func tree<ID: Hashable & Sendable>(
      _ state: TreeNavigation<ID>, label: @escaping (ID) -> String,
      onChange: @escaping (TreeNavigation<ID>) -> Void = { _ in }
    ) -> BehaviorController<TreeNavigation<ID>, BehaviorTree<ID>> {
      BehaviorController(state: state, onChange: onChange) { BehaviorTree($0, label: label) }
    }
  }

  /// UIKit's window conversion supplies the same point-space bounds as XCTest/WDA.
  @MainActor public enum BehaviorMeasurement {
    public static func frame(of view: UIView) -> BehaviorRect? {
      guard let window = view.window, !view.isHidden, view.alpha > 0 else { return nil }
      var ancestor = view.superview
      while let current = ancestor {
        if current.isHidden || current.alpha == 0 { return nil }
        ancestor = current.superview
      }
      let rect = view.convert(view.bounds, to: window)
      return BehaviorRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height)
    }
  }
#endif
