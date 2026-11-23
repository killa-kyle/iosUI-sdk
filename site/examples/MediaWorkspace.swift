import SwiftUI
import UIKit
import UIBehaviorCore
import UIBehaviorSwiftUI
import UIBehaviorUIKit

/// The host owns the edit transaction. The SDK owns crop and overlay transitions.
struct MediaWorkspace: View {
  @State private var savedCrop = CropSelection(width: 600, height: 400, aspect: 1)
  @State private var draftCrop = CropSelection(width: 600, height: 400, aspect: 1)
  @State private var overlays = OverlayStack()
  @State private var caption = "Weekend on the coast"
  @State private var destination = Selection<String>(selected: ["Journal"])
  @State private var savedImage: UIImage?
  @State private var published = false
  @AccessibilityFocusState private var focused: String?

  var body: some View {
    BehaviorOverlayHost($overlays) {
      VStack(alignment: .leading, spacing: 20) {
        Text("Coastal journal").font(.title2.bold())
        Image(uiImage: savedImage ?? Self.image).resizable().scaledToFit()
          .clipShape(RoundedRectangle(cornerRadius: 18))
        HStack {
          Label("Cover image", systemImage: "photo")
          Spacer()
          Button("Edit cover") {
            draftCrop = savedCrop
            _ = overlays.present(BehaviorOverlay("editor", restoreFocus: "edit"))
          }.buttonStyle(.borderedProminent)
            .accessibilityFocused($focused, equals: "edit")
        }
        Text("Saved rotation: \(savedCrop.rotation)°")
          .font(.caption.monospaced()).accessibilityIdentifier("media-saved")
        if published {
          Label("Published to " + destination.selected.sorted().joined(separator: ", "), systemImage: "checkmark.circle.fill")
            .foregroundStyle(.green).accessibilityIdentifier("media-published")
        }
      }
    } overlay: { entry in
      NavigationStack {
        if entry.id == "editor" {
          VStack(alignment: .leading, spacing: 24) {
            BehaviorCropper($draftCrop, image: Image(uiImage: Self.image))
              .frame(height: 300)
            HStack {
              Button("Rotate") { draftCrop.rotateClockwise() }
                .buttonStyle(.bordered)
              Spacer()
              Text("Draft: \(draftCrop.rotation)°").accessibilityIdentifier("media-draft")
            }
            Text("Drag the crop handles to reframe the cover.").foregroundStyle(.secondary)
            Button("Continue to publish") {
              _ = overlays.present(BehaviorOverlay("publish", parent: entry.id, restoreFocus: "continue"))
            }.buttonStyle(.borderedProminent)
              .accessibilityFocused($focused, equals: "continue")
            Spacer()
          }.padding(24).navigationTitle("Edit cover")
            .toolbar {
              ToolbarItem(placement: .cancellationAction) {
                Button("Cancel edit") { overlays.dismiss("editor") }
              }
            }
        } else {
          Form {
            Section("Caption") { TextField("Caption", text: $caption) }
            Section("Destination") {
              BehaviorChoiceList(["Journal", "Portfolio"], selection: $destination, label: { $0 }) { name, selected in
                HStack {
                  Text(name)
                  Spacer()
                  if selected { Image(systemName: "checkmark") }
                }.frame(minHeight: 44)
              }
            }
            Section {
              Button("Publish cover") {
                // Commit only after the final action; closing either sheet keeps the saved crop.
                savedCrop = draftCrop
                savedImage = BehaviorImageCrop.image(Self.image, selection: savedCrop)
                published = true
                overlays.dismiss("editor")
              }.disabled(caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
          }.navigationTitle("Publish cover")
            .toolbar {
              ToolbarItem(placement: .cancellationAction) {
                Button("Back to crop") { overlays.dismiss("publish") }
              }
            }
        }
      }
    } restoreFocus: { focused = $0 }
  }

  static var image: UIImage {
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    return UIGraphicsImageRenderer(size: CGSize(width: 600, height: 400), format: format).image { ctx in
      UIColor(red: 0.74, green: 0.86, blue: 0.94, alpha: 1).setFill()
      ctx.fill(CGRect(x: 0, y: 0, width: 600, height: 400))
      UIColor(red: 0.98, green: 0.76, blue: 0.38, alpha: 1).setFill()
      UIBezierPath(ovalIn: CGRect(x: 430, y: 48, width: 90, height: 90)).fill()
      UIColor(red: 0.16, green: 0.43, blue: 0.53, alpha: 1).setFill()
      let coast = UIBezierPath()
      coast.move(to: CGPoint(x: 0, y: 250))
      coast.addLine(to: CGPoint(x: 200, y: 120))
      coast.addLine(to: CGPoint(x: 340, y: 270))
      coast.addLine(to: CGPoint(x: 600, y: 210))
      coast.addLine(to: CGPoint(x: 600, y: 400))
      coast.addLine(to: CGPoint(x: 0, y: 400))
      coast.close(); coast.fill()
      UIColor(red: 0.24, green: 0.64, blue: 0.74, alpha: 1).setFill()
      ctx.fill(CGRect(x: 0, y: 300, width: 600, height: 100))
    }
  }
}
