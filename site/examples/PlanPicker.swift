import SwiftUI
import UIBehaviorCore
import UIBehaviorSwiftUI

struct PlanPicker: View {
  @Binding var selection: Selection<String>

  var body: some View {
    BehaviorChoiceList(
      ["Personal", "Team", "Studio"], selection: $selection, label: { $0 }
    ) { plan, selected in
      HStack(spacing: 14) {
        Image(systemName: selected ? "checkmark.circle.fill" : "circle")
          .foregroundStyle(selected ? Color.indigo : Color.secondary)
        Text(plan).font(.headline)
        Spacer()
        Text(plan == "Personal" ? "Just you" : "Work together")
          .font(.caption).foregroundStyle(.secondary)
      }
      .padding(18).frame(minHeight: 56)
      .background(
        selected ? Color.indigo.opacity(0.08) : Color.secondary.opacity(0.04),
        in: RoundedRectangle(cornerRadius: 14))
      .overlay(RoundedRectangle(cornerRadius: 14)
        .stroke(selected ? Color.indigo : Color.secondary.opacity(0.2)))
      .padding(.vertical, 5)
    }
  }
}
