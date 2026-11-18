/// Selection is independent of focus. IDs must be stable and unique.
public struct Selection<ID: Hashable & Sendable>: Sendable, Equatable {
    public enum Mode: Sendable { case single, multiple }
    public let mode: Mode
    public private(set) var selected: Set<ID>
    public private(set) var anchor: ID?
    private var anchorBase: Set<ID> = []

    public init(mode: Mode = .single, selected: Set<ID> = []) {
        precondition(mode == .multiple || selected.count <= 1)
        self.mode = mode
        self.selected = selected
    }

    public mutating func choose(_ id: ID, disabled: Set<ID> = []) {
        guard !disabled.contains(id) else { return }
        selected = [id]
        anchor = id
        anchorBase = selected
    }

    public mutating func toggle(_ id: ID, disabled: Set<ID> = []) {
        guard !disabled.contains(id) else { return }
        if selected.contains(id) { selected.remove(id) }
        else if mode == .single { selected = [id] }
        else { selected.insert(id) }
        anchor = id
        anchorBase = selected
    }

    public mutating func extend(to id: ID, order: [ID], disabled: Set<ID> = [], additive: Bool = false) {
        guard !disabled.contains(id), let end = order.firstIndex(of: id) else { return }
        guard mode == .multiple else { choose(id, disabled: disabled); return }
        if anchor == nil || !order.contains(anchor!) { anchor = id; anchorBase = selected }
        guard let start = order.firstIndex(of: anchor!) else { return }
        let range = Set(order[min(start, end)...max(start, end)]).subtracting(disabled)
        selected = additive ? anchorBase.union(range) : range
    }

    public mutating func toggleAll(order: [ID], disabled: Set<ID> = []) {
        let eligible = Set(order).subtracting(disabled)
        guard mode == .multiple else {
            if let first = order.first(where: { !disabled.contains($0) }) { choose(first) }
            return
        }
        if eligible.isSubset(of: selected) { selected.subtract(eligible) }
        else { selected.formUnion(eligible) }
    }

    /// External state changes reset the range anchor; removed IDs are discarded.
    public mutating func reconcile(order: [ID]) {
        selected.formIntersection(order)
        if let anchor, !order.contains(anchor) { self.anchor = nil; anchorBase = [] }
    }

    public mutating func clear() { selected = []; anchor = nil; anchorBase = [] }
}
