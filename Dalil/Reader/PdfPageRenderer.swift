import PDFKit
import UIKit

/// Ouvre un PDF du livre et rend ses pages en images, en arrière-plan, avec un petit cache.
/// Les marges blanches sont recadrées et la page prend la couleur de fond choisie.
final class PdfPageRenderer {
    private let document: PDFDocument
    let pageCount: Int
    private let targetWidthPx: CGFloat

    // PDFKit n'est pas fait pour dessiner sur plusieurs fils à la fois : une seule file, en série.
    private let queue = DispatchQueue(label: "dalil.pdf.render", qos: .userInitiated)
    private let cache = NSCache<NSString, UIImage>()
    private var pending: [NSString: [(UIImage) -> Void]] = [:]

    private static let supersample: CGFloat = 1.6
    private static let whiteThreshold: UInt8 = 248
    private static let cropPadding = 14

    init?(url: URL, screenWidthPx: CGFloat) {
        guard let document = PDFDocument(url: url), document.pageCount > 0 else { return nil }
        self.document = document
        pageCount = document.pageCount
        // On rend plus grand que l'écran : la page reste nette quand on zoome.
        targetWidthPx = min(screenWidthPx * Self.supersample, 2400)
        cache.countLimit = 8
    }

    /// Appelle `completion` sur le fil principal, tout de suite si la page est déjà prête.
    func image(for index: Int, background: ReadingBackground, completion: @escaping (UIImage) -> Void) {
        let key = "\(background.rawValue)-\(index)" as NSString
        if let cached = cache.object(forKey: key) {
            completion(cached)
            return
        }
        if pending[key] != nil {
            pending[key]?.append(completion)
            return
        }
        pending[key] = [completion]
        queue.async { [weak self] in
            guard let self else { return }
            let image = self.render(index: index, background: background)
            DispatchQueue.main.async {
                let waiting = self.pending.removeValue(forKey: key) ?? []
                guard let image else { return }
                self.cache.setObject(image, forKey: key)
                waiting.forEach { $0(image) }
            }
        }
    }

    /// Prépare la page courante et ses voisines avant qu'on les tourne.
    func prefetch(around page: Int, background: ReadingBackground) {
        for index in [page, page + 1, page - 1, page + 2] where (0..<pageCount).contains(index) {
            image(for: index, background: background) { _ in }
        }
    }

    // MARK: Rendu

    private func render(index: Int, background: ReadingBackground) -> UIImage? {
        guard let page = document.page(at: index) else { return nil }
        let box = page.bounds(for: .mediaBox)
        guard box.width > 0, box.height > 0 else { return nil }

        let scale = targetWidthPx / box.width
        let width = Int(box.width * scale)
        let height = Int(box.height * scale)
        guard let context = CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        context.interpolationQuality = .high
        context.scaleBy(x: scale, y: scale)
        context.translateBy(x: -box.minX, y: -box.minY)
        page.draw(with: .mediaBox, to: context)

        guard let full = context.makeImage() else { return nil }
        let cropped = Self.contentRect(of: context, width: width, height: height)
            .flatMap { full.cropping(to: $0) } ?? full
        return Self.colorize(cropped, background: background)
    }

    /// Cadre du texte (tout ce qui n'est pas blanc), avec une petite marge.
    private static func contentRect(of context: CGContext, width: Int, height: Int) -> CGRect? {
        guard let data = context.data?.assumingMemoryBound(to: UInt8.self) else { return nil }
        let bytesPerRow = context.bytesPerRow
        var minX = width, minY = height, maxX = -1, maxY = -1

        for y in 0..<height {
            let row = data + y * bytesPerRow
            var x = 0
            while x < width {
                let p = row + x * 4
                if p[0] < whiteThreshold || p[1] < whiteThreshold || p[2] < whiteThreshold {
                    if x < minX { minX = x }
                    if x > maxX { maxX = x }
                    if y < minY { minY = y }
                    if y > maxY { maxY = y }
                }
                x += 1
            }
        }
        guard maxX >= minX, maxY >= minY else { return nil }

        let left = max(minX - cropPadding, 0)
        let top = max(minY - cropPadding, 0)
        let right = min(maxX + cropPadding, width - 1)
        let bottom = min(maxY + cropPadding, height - 1)
        return CGRect(x: left, y: top, width: right - left + 1, height: bottom - top + 1)
    }

    /// Fond clair : la page est multipliée par la couleur (le blanc prend la teinte, l'encre reste noire).
    /// Fond sombre : la page est inversée, le texte devient clair sur le gris foncé.
    private static func colorize(_ image: CGImage, background: ReadingBackground) -> UIImage {
        let size = CGSize(width: image.width, height: image.height)
        let rect = CGRect(origin: .zero, size: size)
        let format = UIGraphicsImageRendererFormat.preferred()
        format.scale = 1
        format.opaque = true
        let page = UIImage(cgImage: image)

        return UIGraphicsImageRenderer(size: size, format: format).image { renderer in
            let context = renderer.cgContext
            if background.isDark {
                page.draw(in: rect)
                context.setBlendMode(.difference)
                UIColor.white.setFill()
                context.fill(rect)
                context.setBlendMode(.lighten)
                background.uiColor.setFill()
                context.fill(rect)
            } else {
                background.uiColor.setFill()
                context.fill(rect)
                page.draw(in: rect, blendMode: .multiply, alpha: 1)
            }
        }
    }
}
