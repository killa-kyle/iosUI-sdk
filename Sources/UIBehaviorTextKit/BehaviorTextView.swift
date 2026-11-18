#if canImport(UIKit)
  import UIKit
  import UIBehaviorCore

  /// TextKit supplies selection, composition, undo, paste and platform accessibility.
  @MainActor public final class BehaviorTextView: UITextView, UITextViewDelegate {
    public var onDocumentChange: ((RichTextDocument) -> Void)?
    private var applying = false
    public override init(frame: CGRect, textContainer: NSTextContainer?) {
      super.init(frame: frame, textContainer: textContainer)
      delegate = self
      allowsEditingTextAttributes = true
      font = .preferredFont(forTextStyle: .body)
      adjustsFontForContentSizeCategory = true
      let toolbar = UIToolbar()
      toolbar.sizeToFit()
      toolbar.items = [
        UIBarButtonItem(title: "Bold", style: .plain, target: self, action: #selector(bold)),
        UIBarButtonItem(title: "Italic", style: .plain, target: self, action: #selector(italic)),
        UIBarButtonItem(
          title: "Underline", style: .plain, target: self, action: #selector(underline)),
      ]
      inputAccessoryView = toolbar
    }
    public required init?(coder: NSCoder) { nil }
    public var document: RichTextDocument {
      var runs: [RichTextRun] = []
      attributedText.enumerateAttributes(in: NSRange(location: 0, length: attributedText.length)) {
        attrs, range, _ in
        if let font = attrs[.font] as? UIFont {
          if font.fontDescriptor.symbolicTraits.contains(.traitBold) {
            runs.append(.init(location: range.location, length: range.length, style: .bold))
          }
          if font.fontDescriptor.symbolicTraits.contains(.traitItalic) {
            runs.append(.init(location: range.location, length: range.length, style: .italic))
          }
        }
        if let underline = attrs[.underlineStyle] as? Int, underline != 0 {
          runs.append(.init(location: range.location, length: range.length, style: .underline))
        }
        if let link = attrs[.link] {
          runs.append(
            .init(
              location: range.location, length: range.length, style: .link(String(describing: link))
            ))
        }
      }
      return RichTextDocument(text, runs: runs, selection: selectedRange)
    }
    public func setDocument(_ document: RichTextDocument) {
      guard !applying, markedTextRange == nil else { return }
      applying = true
      defer { applying = false }
      let attributed = NSMutableAttributedString(
        string: document.text,
        attributes: [
          .font: UIFont.preferredFont(forTextStyle: .body), .foregroundColor: UIColor.label,
        ])
      for run in document.runs {
        let range = NSRange(location: run.location, length: run.length)
        switch run.style {
        case .bold, .italic:
          attributed.enumerateAttribute(.font, in: range) { value, subrange, _ in
            let font = value as? UIFont ?? UIFont.preferredFont(forTextStyle: .body)
            var traits = font.fontDescriptor.symbolicTraits
            traits.insert(run.style == .bold ? .traitBold : .traitItalic)
            if let descriptor = font.fontDescriptor.withSymbolicTraits(traits) {
              attributed.addAttribute(
                .font, value: UIFont(descriptor: descriptor, size: font.pointSize), range: subrange)
            }
          }
        case .underline:
          attributed.addAttribute(
            .underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
        case .link(let href):
          if let url = URL(string: href),
            ["https", "http", "mailto"].contains(url.scheme?.lowercased() ?? "")
          {
            attributed.addAttribute(.link, value: url, range: range)
          }
        }
      }
      attributedText = attributed
      selectedRange = document.selection
    }
    public func textViewDidChange(_ textView: UITextView) {
      if !applying { onDocumentChange?(document) }
    }
    public func textViewDidChangeSelection(_ textView: UITextView) {
      if !applying, markedTextRange == nil { onDocumentChange?(document) }
    }
    public func apply(_ style: RichTextStyle) {
      var next = document
      next.toggle(style)
      switch style {
      case .bold: toggleBoldface(nil)
      case .italic: toggleItalics(nil)
      case .underline: toggleUnderline(nil)
      case .link: setDocument(next)
      }
      onDocumentChange?(document)
    }
    @objc private func bold() { apply(.bold) }
    @objc private func italic() { apply(.italic) }
    @objc private func underline() { apply(.underline) }
  }
#endif
