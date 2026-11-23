import SwiftUI
import UIBehaviorCore
import UIBehaviorSwiftUI

struct ToolActivity: View {
  @State private var details = Disclosure(isOpen: true)

  var body: some View {
    BehaviorDisclosure($details) {
      Label("Read project files", systemImage: "checkmark.circle.fill")
        .font(.headline)
    } content: {
      VStack(alignment: .leading, spacing: 14) {
        ForEach(["Package.swift", "Sources/App.swift", "README.md"], id: \.self) { file in
          Label(file, systemImage: "doc.text")
            .font(.subheadline.monospaced()).foregroundStyle(.secondary)
        }
      }.frame(maxWidth: .infinity, alignment: .leading).padding(.top, 16)
    }
    .tint(.indigo).padding(20)
    .background(Color.secondary.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
  }
}
