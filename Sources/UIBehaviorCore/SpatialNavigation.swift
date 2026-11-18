public enum NavigationDirection: Sendable, Equatable { case up, down, left, right, first, last }

public struct GridCell: Hashable, Sendable, Codable {
  public let row: Int
  public let column: Int
  public init(_ row: Int, _ column: Int) {
    self.row = row
    self.column = column
  }
}

public struct GridNavigation: Sendable {
  public let rows: Int
  public let columns: Int
  public var disabled: Set<GridCell>
  public private(set) var focused: GridCell?
  public private(set) var selected: Set<GridCell> = []
  private var anchor: GridCell?
  public init(rows: Int, columns: Int, disabled: Set<GridCell> = []) {
    precondition(rows >= 0 && columns >= 0 && rows <= 100_000 && columns <= 100_000)
    self.rows = rows
    self.columns = columns
    self.disabled = disabled
  }
  public func contains(_ cell: GridCell) -> Bool {
    (0..<rows).contains(cell.row) && (0..<columns).contains(cell.column)
  }
  public mutating func focus(_ cell: GridCell, extending: Bool = false) {
    guard contains(cell), !disabled.contains(cell) else { return }
    if extending, let a = anchor ?? focused {
      // Bound work to the caller's explicit grid, never an unbounded coordinate range.
      guard (abs(cell.row - a.row) + 1) * (abs(cell.column - a.column) + 1) <= 1_000_000 else {
        return
      }
      anchor = a
      selected = Set(
        (min(a.row, cell.row)...max(a.row, cell.row)).flatMap { row in
          (min(a.column, cell.column)...max(a.column, cell.column)).map { GridCell(row, $0) }
        }
      ).subtracting(disabled)
    } else {
      selected = [cell]
      anchor = cell
    }
    focused = cell
  }
  public mutating func move(
    _ direction: NavigationDirection, extending: Bool = false,
    rightToLeft: Bool = false
  ) {
    guard rows > 0, columns > 0 else { return }
    if focused == nil {
      var first = GridCell(0, 0)
      while contains(first), disabled.contains(first) {
        first =
          first.column + 1 < columns
          ? GridCell(first.row, first.column + 1) : GridCell(first.row + 1, 0)
      }
      focus(first)
      return
    }
    var cell = focused ?? GridCell(0, 0)
    let horizontal = rightToLeft ? -1 : 1
    switch direction {
    case .first: cell = GridCell(cell.row, 0)
    case .last: cell = GridCell(cell.row, columns - 1)
    case .up: cell = GridCell(cell.row - 1, cell.column)
    case .down: cell = GridCell(cell.row + 1, cell.column)
    case .left: cell = GridCell(cell.row, cell.column - horizontal)
    case .right: cell = GridCell(cell.row, cell.column + horizontal)
    }
    let delta: (Int, Int)
    switch direction {
    case .up: delta = (-1, 0)
    case .down: delta = (1, 0)
    case .left: delta = (0, -horizontal)
    case .right: delta = (0, horizontal)
    case .first: delta = (0, 1)
    case .last: delta = (0, -1)
    }
    while contains(cell), disabled.contains(cell) {
      cell = GridCell(cell.row + delta.0, cell.column + delta.1)
    }
    focus(cell, extending: extending)
  }
}

public struct BehaviorTreeNode<ID: Hashable & Sendable>: Sendable {
  public let id: ID
  public var children: [Self]
  public var disabled: Bool
  public init(_ id: ID, children: [Self] = [], disabled: Bool = false) {
    self.id = id
    self.children = children
    self.disabled = disabled
  }
}

public enum TreeBehaviorError: Error { case duplicateID }

public struct TreeNavigation<ID: Hashable & Sendable>: Sendable {
  public let roots: [BehaviorTreeNode<ID>]
  public private(set) var expanded: Set<ID>
  public private(set) var focused: ID?
  public private(set) var selection = Selection<ID>(mode: .multiple)
  public init(_ roots: [BehaviorTreeNode<ID>], expanded: Set<ID> = []) throws {
    var seen = Set<ID>()
    func validate(_ nodes: [BehaviorTreeNode<ID>]) throws {
      for node in nodes {
        guard seen.insert(node.id).inserted else { throw TreeBehaviorError.duplicateID }
        try validate(node.children)
      }
    }
    try validate(roots)
    self.roots = roots
    self.expanded = expanded.intersection(seen)
  }
  public var visible: [(node: BehaviorTreeNode<ID>, depth: Int, parent: ID?)] {
    func flatten(_ nodes: [BehaviorTreeNode<ID>], depth: Int, parent: ID?)
      -> [(BehaviorTreeNode<ID>, Int, ID?)]
    {
      nodes.flatMap { node in
        [(node, depth, parent)]
          + (expanded.contains(node.id)
            ? flatten(node.children, depth: depth + 1, parent: node.id) : [])
      }
    }
    return flatten(roots, depth: 0, parent: nil)
  }
  public mutating func toggle(_ id: ID) {
    guard let row = visible.first(where: { $0.node.id == id }),
      !row.node.disabled, !row.node.children.isEmpty
    else { return }
    if expanded.remove(id) == nil { expanded.insert(id) }
    if let focus = focused, !visible.contains(where: { $0.node.id == focus }) { focused = id }
  }
  public mutating func select(_ id: ID, extending: Bool = false, additive: Bool = false) {
    let rows = visible
    let order = rows.map { $0.node.id }
    let disabled = Set(rows.filter { $0.node.disabled }.map { $0.node.id })
    guard order.contains(id), !disabled.contains(id) else { return }
    focused = id
    if extending {
      selection.extend(to: id, order: order, disabled: disabled, additive: additive)
    } else if additive {
      selection.toggle(id, disabled: disabled)
    } else {
      selection.choose(id, disabled: disabled)
    }
  }
  public mutating func move(_ direction: NavigationDirection) {
    let rows = visible.filter { !$0.node.disabled }
    guard !rows.isEmpty else { return }
    guard let current = focused, let index = rows.firstIndex(where: { $0.node.id == current })
    else {
      focused = rows[0].node.id
      return
    }
    switch direction {
    case .first: focused = rows.first?.node.id
    case .last: focused = rows.last?.node.id
    case .up: focused = rows[max(0, index - 1)].node.id
    case .down: focused = rows[min(rows.count - 1, index + 1)].node.id
    case .right:
      if !rows[index].node.children.isEmpty {
        if expanded.contains(current) {
          if let child = rows.dropFirst(index + 1).first, child.depth > rows[index].depth {
            focused = child.node.id
          }
        } else {
          expanded.insert(current)
        }
      }
    case .left:
      if expanded.contains(current) {
        expanded.remove(current)
      } else {
        focused = rows[index].parent ?? current
      }
    }
  }
}
