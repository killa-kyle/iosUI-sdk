import SwiftUI

/// The site's palette applied to actual native adapters, for reproducible captures.
enum CatalogPalette {
  static let paper = Color(red: 250 / 255, green: 250 / 255, blue: 248 / 255)
  static let ink = Color(red: 37 / 255, green: 40 / 255, blue: 35 / 255)
  static let muted = Color(red: 101 / 255, green: 106 / 255, blue: 97 / 255)
  static let line = Color(red: 228 / 255, green: 230 / 255, blue: 223 / 255)
  static let accent = Color(red: 48 / 255, green: 75 / 255, blue: 208 / 255)
}
struct CatalogShowcase<Content: View>: View {
  let title: String
  let content: Content
  init(title: String, @ViewBuilder content: () -> Content) {
    self.title = title
    self.content = content()
  }
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        HStack(spacing: 8) {
          Image(systemName: "arrow.up.right.square.fill").font(.title2)
          Text("iosUI-sdk").font(.headline)
          Spacer()
          Text("SwiftUI").font(.caption.monospaced()).foregroundStyle(CatalogPalette.muted)
        }
        Text(title).font(.system(size: 30, weight: .bold)).accessibilityAddTraits(.isHeader)
        Text("SwiftUI components using iosUI-sdk.")
          .foregroundStyle(CatalogPalette.muted).font(.subheadline)
        VStack(alignment: .leading, spacing: 20) { content }
          .font(.system(size: 15))
          .padding(16).frame(maxWidth: .infinity, alignment: .leading)
          .background(.white, in: RoundedRectangle(cornerRadius: 12))
          .overlay(RoundedRectangle(cornerRadius: 12).stroke(CatalogPalette.line, lineWidth: 1))
        Text("Native iOS · Actual package adapters")
          .font(.caption.monospaced()).foregroundStyle(CatalogPalette.muted)
      }.padding(20).frame(maxWidth: 600, alignment: .leading)
    }
    .foregroundStyle(CatalogPalette.ink).background(CatalogPalette.paper)
    .tint(CatalogPalette.accent).buttonStyle(.bordered)
    .toolbar(.hidden, for: .navigationBar).preferredColorScheme(.light)
  }
}
