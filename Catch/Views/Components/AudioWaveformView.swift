import SwiftUI

/// Animated audio waveform visualizer that pulses with speech audio metering.
public struct AudioWaveformView: View {
    public let audioLevel: Float
    public let barCount: Int = 18

    public init(audioLevel: Float) {
        self.audioLevel = audioLevel
    }

    public var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<barCount, id: \.self) { index in
                WaveformBar(
                    index: index,
                    totalBars: barCount,
                    level: audioLevel
                )
            }
        }
        .frame(height: 36)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Theme.secondaryBackground)
        .clipShape(Capsule())
    }
}

private struct WaveformBar: View {
    let index: Int
    let totalBars: Int
    let level: Float

    var height: CGFloat {
        let center = Float(totalBars) / 2.0
        let distanceFromCenter = abs(Float(index) - center)
        let falloff = max(0.3, 1.0 - (distanceFromCenter / center) * 0.6)
        
        let baseHeight: CGFloat = 6.0
        let maxAdditionalHeight: CGFloat = 26.0
        let dynamicHeight = CGFloat(level * falloff) * maxAdditionalHeight
        return baseHeight + dynamicHeight
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(
                LinearGradient(
                    colors: [Theme.brandTint, Theme.brandTint.opacity(0.6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 3, height: height)
            .animation(Theme.springQuick, value: height)
    }
}
