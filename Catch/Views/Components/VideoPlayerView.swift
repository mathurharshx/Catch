import SwiftUI
import AVFoundation

/// Hardware-accelerated native video player view for launch splash and micro-animations.
public struct VideoPlayerView: UIViewRepresentable {
    public let videoName: String
    public let videoExtension: String
    public let onFinished: (() -> Void)?

    public init(
        videoName: String = "highqualitycatchy",
        videoExtension: String = "mp4",
        onFinished: (() -> Void)? = nil
    ) {
        self.videoName = videoName.replacingOccurrences(of: ".\(videoExtension)", with: "")
        self.videoExtension = videoExtension
        self.onFinished = onFinished
    }

    public func makeUIView(context: Context) -> PlayerContainerView {
        let container = PlayerContainerView()
        container.backgroundColor = .clear

        if let url = resolveVideoURL() {
            container.setupPlayer(with: url, onFinished: onFinished)
        }
        return container
    }

    public func updateUIView(_ uiView: PlayerContainerView, context: Context) {
        // No-op
    }

    private func resolveVideoURL() -> URL? {
        if let url = Bundle.main.url(forResource: videoName, withExtension: videoExtension) {
            return url
        }
        let fallbackPaths = [
            "/Users/harshmathur/Projects/Catch/Catch/Resources/\(videoName).\(videoExtension)",
            "/Users/harshmathur/Projects/Catch/\(videoName).\(videoExtension)"
        ]
        for path in fallbackPaths {
            if FileManager.default.fileExists(atPath: path) {
                return URL(fileURLWithPath: path)
            }
        }
        return nil
    }

    public class PlayerContainerView: UIView {
        private var player: AVPlayer?
        private var playerLayer: AVPlayerLayer?
        private var finishObserver: Any?
        private var onFinished: (() -> Void)?

        public override static var layerClass: AnyClass {
            return AVPlayerLayer.self
        }

        public override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = .clear
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            backgroundColor = .clear
        }

        public func setupPlayer(with url: URL, onFinished: (() -> Void)?) {
            self.onFinished = onFinished
            let item = AVPlayerItem(url: url)
            let player = AVPlayer(playerItem: item)
            player.isMuted = true
            player.automaticallyWaitsToMinimizeStalling = false
            self.player = player

            if let layer = self.layer as? AVPlayerLayer {
                layer.player = player
                layer.videoGravity = .resizeAspect
                layer.backgroundColor = UIColor.clear.cgColor
            }

            finishObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: item,
                queue: .main
            ) { [weak self] _ in
                self?.onFinished?()
            }

            player.play()
        }

        public override func layoutSubviews() {
            super.layoutSubviews()
            if let layer = self.layer as? AVPlayerLayer {
                layer.frame = bounds
            }
        }

        deinit {
            if let observer = finishObserver {
                NotificationCenter.default.removeObserver(observer)
            }
            player?.pause()
            player = nil
        }
    }
}
