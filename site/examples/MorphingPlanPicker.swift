import SwiftUI
import UIBehaviorCore
import UIBehaviorSwiftUI

struct MorphingPlanPicker: View {
  enum Appearance: String, CaseIterable {
    case cards = "Cards", segments = "Segments", chips = "Chips"
  }
  @State private var selection = Selection<String>(selected: ["Team"])
  @State private var appearance = Appearance.cards
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  private var layout: AnyLayout {
    appearance == .cards
      ? AnyLayout(VStackLayout(spacing: 10))
      : AnyLayout(HStackLayout(spacing: appearance == .segments ? 0 : 8))
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      Text("Choose a plan").font(.title2.bold())
      BehaviorChoiceList(
        ["Personal", "Team", "Studio"], selection: $selection,
        layout: layout, label: { $0 }
      ) { plan, selected in
        HStack(spacing: 12) {
          if appearance == .cards {
            Image(systemName: selected ? "checkmark.circle.fill" : "circle")
          }
          Text(plan).font(.system(size: appearance == .chips ? 14 : 16, weight: .semibold))
          if appearance == .cards {
            Spacer()
            Text(plan == "Personal" ? "Just you" : "Work together")
              .font(.caption).foregroundStyle(.secondary)
          }
        }
        .padding(.horizontal, appearance == .cards ? 18 : 14)
        .frame(maxWidth: appearance == .chips ? nil : .infinity)
        .frame(height: appearance == .cards ? 72 : 44)
        .foregroundStyle(selected ? Color.white : Color.primary)
        .background(
          selected ? Color.indigo : Color.secondary.opacity(0.08),
          in: RoundedRectangle(cornerRadius: appearance == .chips ? 22 : 12))
        .padding(appearance == .segments ? 3 : 0)
      }
      .frame(height: 244, alignment: .top)
      .accessibilityElement(children: .contain).accessibilityIdentifier("morph-component")

      Text("Selected: " + selection.selected.sorted().joined(separator: ", "))
        .font(.caption.monospaced()).accessibilityIdentifier("morph-selection")
      HStack {
        ForEach(Appearance.allCases, id: \.self) { style in
          Button(style.rawValue) {
            withAnimation(reduceMotion ? nil : .spring(response: 0.7, dampingFraction: 0.8)) {
              appearance = style
            }
          }
          .buttonStyle(.bordered)
          .accessibilityAddTraits(appearance == style ? .isSelected : [])
        }
      }
      Text("Selection + BehaviorChoiceList").font(.caption.monospaced())
    }
  }
}
