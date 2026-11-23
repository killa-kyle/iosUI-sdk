import SwiftUI
import UIBehaviorCore
import UIBehaviorSwiftUI

struct DeleteProjectButton: View {
  let project: String
  let onDelete: () -> Void
  @State private var confirmation = Disclosure()

  var body: some View {
    Button("Delete project", role: .destructive) { confirmation.open() }
      .buttonStyle(.bordered)
      .behaviorSheet($confirmation) {
        VStack(alignment: .leading, spacing: 20) {
          Image(systemName: "trash").font(.largeTitle).foregroundStyle(.red)
          Text("Delete \(project)?").font(.title2.bold())
          Text("The project and its files will be permanently deleted.")
            .foregroundStyle(.secondary)
          HStack {
            Button("Cancel") { confirmation.dismiss(.action) }
              .buttonStyle(.bordered)
            Spacer()
            Button("Delete", role: .destructive) {
              confirmation.dismiss(.action)
              onDelete()
            }.buttonStyle(.borderedProminent).tint(.red)
          }
        }
        .padding(28)
        .presentationDetents([.height(300)])
      }
  }
}
