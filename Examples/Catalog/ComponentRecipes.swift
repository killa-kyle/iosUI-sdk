import SwiftUI
import UIBehaviorCore

enum ComponentRecipe: String, CaseIterable, Identifiable {
  case confirmation, selection, activity
  var id: String { rawValue }
  var title: String {
    switch self {
    case .confirmation: "A confirmation sheet"
    case .selection: "A plan picker"
    case .activity: "Expandable tool activity"
    }
  }
  var adapter: String {
    switch self {
    case .confirmation: "Disclosure + behaviorSheet"
    case .selection: "Selection + BehaviorChoiceList"
    case .activity: "Disclosure + BehaviorDisclosure"
    }
  }
}

struct ComponentRecipes: View {
  var body: some View {
    List(ComponentRecipe.allCases) { recipe in
      NavigationLink(recipe.title) { ComponentRecipeDemo(recipe: recipe) }
    }.navigationTitle("Component recipes")
  }
}

struct ComponentRecipeDemo: View {
  let recipe: ComponentRecipe
  @State private var selection = Selection<String>(selected: ["Personal"])
  @State private var deletions = 0

  var body: some View {
    CatalogShowcase(title: recipe.title) {
      Text(recipe.adapter).font(.caption.monospaced()).foregroundStyle(CatalogPalette.accent)
      switch recipe {
      case .confirmation:
        Label("Weekend project", systemImage: "folder.fill").font(.title3.bold())
        Text("A reusable button with a native confirmation sheet.")
          .foregroundStyle(.secondary)
        DeleteProjectButton(project: "Weekend project") { deletions += 1 }
        Text(deletions == 0 ? "Project kept" : "Deleted locally: \(deletions)")
          .font(.caption).accessibilityIdentifier("recipe-result")
      case .selection:
        Text("Choose your workspace").font(.title3.bold())
        PlanPicker(selection: $selection)
          .accessibilityElement(children: .contain).accessibilityIdentifier("recipe-component")
        Text("Selected: " + selection.selected.sorted().joined(separator: ", "))
          .font(.caption).accessibilityIdentifier("recipe-result")
      case .activity:
        ToolActivity()
          .frame(
            minHeight: ProcessInfo.processInfo.arguments.contains("--motion-capture") ? 200 : nil,
            alignment: .top)
          .accessibilityElement(children: .contain).accessibilityIdentifier("recipe-component")
      }
      Text("This example runs locally. No account or server needed.")
        .font(.caption).foregroundStyle(.secondary)
    }
  }
}
