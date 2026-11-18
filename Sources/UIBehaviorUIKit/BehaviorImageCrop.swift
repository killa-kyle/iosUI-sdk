#if canImport(UIKit)
  import UIKit
  import UIBehaviorCore

  @MainActor public enum BehaviorImageCrop {
    /// Resolves UIImage orientation, applies quarter-turn rotation, then crops physical pixels.
    public static func image(_ image: UIImage, selection: CropSelection) -> UIImage? {
      let original = CGSize(
        width: image.size.width * image.scale, height: image.size.height * image.scale)
      guard original.width.isFinite, original.height.isFinite, original.width >= 1,
        original.height >= 1
      else { return nil }
      let turned = selection.rotation % 180 != 0
      let size = turned ? CGSize(width: original.height, height: original.width) : original
      guard abs(selection.resize.bounds.width - size.width) < 0.001,
        abs(selection.resize.bounds.height - size.height) < 0.001, selection.rect.isValid
      else { return nil }
      let format = UIGraphicsImageRendererFormat()
      format.scale = 1
      let normalized = UIGraphicsImageRenderer(size: size, format: format).image { context in
        context.cgContext.translateBy(x: size.width / 2, y: size.height / 2)
        context.cgContext.rotate(by: CGFloat(selection.rotation) * .pi / 180)
        image.draw(
          in: CGRect(
            x: -original.width / 2, y: -original.height / 2, width: original.width,
            height: original.height))
      }
      let rect = selection.rect
      let area = CGRect(x: rect.x, y: rect.y, width: rect.width, height: rect.height)
        .integral.intersection(CGRect(origin: .zero, size: size))
      guard area.width > 0, area.height > 0, let cg = normalized.cgImage?.cropping(to: area) else {
        return nil
      }
      return UIImage(cgImage: cg, scale: 1, orientation: .up)
    }
  }
#endif
