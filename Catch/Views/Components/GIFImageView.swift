import SwiftUI
import ImageIO

/// High-performance SwiftUI GIF view backed by native animated UIImage.
public struct GIFImageView: UIViewRepresentable {
    public let gifName: String

    public init(gifName: String) {
        self.gifName = gifName
    }

    public static var cachedImages: [String: UIImage] = [:]

    public func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .clear
        imageView.clipsToBounds = true
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        if let cached = GIFImageView.cachedImages[gifName] {
            imageView.image = cached
        } else {
            // Load frame 0 immediately for instant display (<3ms)
            if let firstFrame = GIFImageView.loadFirstFrame(name: gifName) {
                imageView.image = firstFrame
            }
            // Decode full animated sequence asynchronously
            DispatchQueue.global(qos: .userInitiated).async {
                if let animated = GIFImageView.loadAnimatedImage(name: gifName) {
                    DispatchQueue.main.async {
                        GIFImageView.cachedImages[gifName] = animated
                        imageView.image = animated
                    }
                }
            }
        }
        return imageView
    }

    public func updateUIView(_ uiView: UIImageView, context: Context) {
        if uiView.image == nil {
            if let cached = GIFImageView.cachedImages[gifName] {
                uiView.image = cached
            }
        }
    }

    public static func loadFirstFrame(name: String) -> UIImage? {
        let cleanName = name.replacingOccurrences(of: ".gif", with: "")
        guard let url = Bundle.main.url(forResource: cleanName, withExtension: "gif") ??
                        Bundle.main.url(forResource: name, withExtension: nil) ??
                        resolveFallbackURL(name: name) else {
            return nil
        }
        guard let data = try? Data(contentsOf: url),
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              CGImageSourceGetCount(source) > 0 else {
            return nil
        }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: 600
        ]
        if let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) ??
                         CGImageSourceCreateImageAtIndex(source, 0, nil) {
            return UIImage(cgImage: cgImage)
        }
        return nil
    }

    public static func loadAnimatedImage(name: String) -> UIImage? {
        if let cached = cachedImages[name] { return cached }

        let cleanName = name.replacingOccurrences(of: ".gif", with: "")
        guard let url = Bundle.main.url(forResource: cleanName, withExtension: "gif") ??
                        Bundle.main.url(forResource: name, withExtension: nil) ??
                        resolveFallbackURL(name: name) else {
            return nil
        }

        guard let data = try? Data(contentsOf: url),
              let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }

        let count = CGImageSourceGetCount(source)
        guard count > 0 else { return nil }

        var images: [UIImage] = []
        var totalDuration: Double = 0.0

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 600
        ]

        for i in 0..<count {
            if let cgImage = CGImageSourceCreateThumbnailAtIndex(source, i, options as CFDictionary) ??
                             CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(UIImage(cgImage: cgImage))
            }

            if let properties = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [CFString: Any],
               let gifProperties = properties[kCGImagePropertyGIFDictionary] as? [CFString: Any] {
                let delay = (gifProperties[kCGImagePropertyGIFUnclampedDelayTime] as? Double) ??
                            (gifProperties[kCGImagePropertyGIFDelayTime] as? Double) ?? 0.04
                totalDuration += delay
            } else {
                totalDuration += 0.04
            }
        }

        if images.isEmpty { return nil }
        let duration = totalDuration > 0 ? totalDuration : Double(count) * 0.04
        let animated = UIImage.animatedImage(with: images, duration: duration)
        if let animated = animated {
            cachedImages[name] = animated
        }
        return animated
    }

    public static func resolveFallbackURL(name: String) -> URL? {
        let possiblePaths = [
            "/Users/harshmathur/Projects/Catch/Catch/Resources/\(name)",
            "/Users/harshmathur/Projects/Catch/Catch/Resources/\(name).gif"
        ]
        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                return URL(fileURLWithPath: path)
            }
        }
        return nil
    }
}
