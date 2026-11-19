#if canImport(UIKit)
  import SwiftUI
  import UIBehaviorCore
  import UIBehaviorTextKit

  public struct BehaviorRichTextEditor: UIViewRepresentable {
    @Binding private var document: RichTextDocument
    private let label: String
    public init(_ label: String, document: Binding<RichTextDocument>) {
      self.label = label
      _document = document
    }
    public func makeUIView(context: Context) -> BehaviorTextView {
      let view = BehaviorTextView(frame: .zero, textContainer: nil)
      view.accessibilityLabel = label
      view.setDocument(document)
      return view
    }
    public func updateUIView(_ view: BehaviorTextView, context: Context) {
      view.onDocumentChange = { document = $0 }
      // Do not replace attributed storage during marked-text composition or reset the caret every render.
      if view.document != document { view.setDocument(document) }
    }
  }
#endif
