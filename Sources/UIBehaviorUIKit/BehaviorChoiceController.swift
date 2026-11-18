#if canImport(UIKit)
import UIKit
import UIBehaviorCore

/// A first-class UIKit adapter. Install as a child controller or push normally.
/// Native table focus, Dynamic Type and VoiceOver remain owned by UIKit.
@MainActor
open class BehaviorChoiceController<ID: Hashable & Sendable>: UITableViewController {
    public private(set) var ids: [ID]
    public private(set) var selection: Selection<ID>
    public var disabled: Set<ID> = [] { didSet { tableView.reloadData() } }
    public var onSelectionChange: ((Selection<ID>) -> Void)?
    public var onReorder: (([ID]) -> Void)?
    private let label: (ID) -> String
    private var typeahead = Typeahead()
    private var navigation = FocusNavigation<ID>()

    public init(_ ids: [ID], selection: Selection<ID> = Selection(), label: @escaping (ID) -> String) {
        precondition(Set(ids).count == ids.count)
        self.ids = ids; self.selection = selection; self.label = label
        super.init(style: .insetGrouped)
    }
    @available(*, unavailable)
    public required init?(coder: NSCoder) { fatalError("Use init(_:selection:label:)") }

    public func update(ids: [ID], selection: Selection<ID>) {
        precondition(Set(ids).count == ids.count)
        self.ids = ids; self.selection = selection
        self.selection.reconcile(order: ids)
        tableView.reloadData()
    }
    open override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { ids.count }
    open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let id = ids[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "choice") ?? UITableViewCell(style: .default, reuseIdentifier: "choice")
        var config = cell.defaultContentConfiguration()
        config.text = label(id)
        config.textProperties.color = disabled.contains(id) ? .secondaryLabel : .label
        cell.contentConfiguration = config
        cell.accessoryType = selection.selected.contains(id) ? .checkmark : .none
        cell.accessibilityTraits = [.button]
        if selection.selected.contains(id) { cell.accessibilityTraits.insert(.selected) }
        if disabled.contains(id) { cell.accessibilityTraits.insert(.notEnabled) }
        return cell
    }
    open override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let id = ids[indexPath.row]
        if selection.mode == .multiple { selection.toggle(id, disabled: disabled) }
        else { selection.choose(id, disabled: disabled) }
        tableView.deselectRow(at: indexPath, animated: false)
        tableView.reloadData()
        if !disabled.contains(id) { onSelectionChange?(selection) }
    }
    open override func tableView(_ tableView: UITableView, canFocusRowAt indexPath: IndexPath) -> Bool {
        !disabled.contains(ids[indexPath.row])
    }
    open override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        onReorder != nil && !disabled.contains(ids[indexPath.row])
    }
    open override func tableView(_ tableView: UITableView, moveRowAt source: IndexPath, to destination: IndexPath) {
        if Reorder.move(ids[source.row], to: destination.row, in: &ids, disabled: disabled) { onReorder?(ids) }
        tableView.reloadData()
    }

    /// Call from your UIKeyCommand or input handler. Returns the target to focus.
    @discardableResult
    public func moveFocus(_ movement: FocusNavigation<ID>.Movement) -> ID? {
        let id = navigation.move(movement, order: ids, disabled: disabled)
        if let id, let row = ids.firstIndex(of: id) {
            tableView.selectRow(at: IndexPath(row: row, section: 0), animated: false, scrollPosition: .none)
        }
        return id
    }
    @discardableResult
    public func search(_ text: String, at time: TimeInterval = ProcessInfo.processInfo.systemUptime) -> ID? {
        let eligible = ids.filter { !disabled.contains($0) }
        let current = navigation.focused.flatMap { eligible.firstIndex(of: $0) }
        guard let index = typeahead.search(text, labels: eligible.map(label), current: current, at: time) else { return nil }
        let id = eligible[index]
        navigation.focus(id, order: ids, disabled: disabled)
        if let row = ids.firstIndex(of: id) { tableView.scrollToRow(at: IndexPath(row: row, section: 0), at: .middle, animated: false) }
        return id
    }
}
#endif
