import SwiftUI

/// Animated audio waveform visualizer featuring Catchy listening with headphones.
public struct AudioWaveformView: View {
    public let audioLevel: Float
    public let barCount: Int = 16

    public init(audioLevel: Float) {
        self.audioLevel = audioLevel
    }

    public var body: some View {
        HStack(spacing: 12) {
            CatchyMascotView(pose: .listening, size: 44, animated: true)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 6, height: 6)

                    Text("Catchy is listening...")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.primaryText)
                }

                HStack(spacing: 3) {
                    ForEach(0..<barCount, id: \.self) { index in
                        WaveformBar(
                            index: index,
                            totalBars: barCount,
                            level: audioLevel
                        )
                    }
                }
                .frame(height: 24)
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Theme.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Theme.brandTint.opacity(0.2), lineWidth: 1)
        )
    }
}

private struct WaveformBar: View {
    let index: Int
    let totalBars: Int
    let level: Float

    var height: CGFloat {
        let center = Float(totalBars) / 2.0
        let distanceFromCenter = abs(Float(index) - center)
        let falloff = max(0.35, 1.0 - (distanceFromCenter / center) * 0.5)

        let baseHeight: CGFloat = 4.0
        let maxAdditionalHeight: CGFloat = 20.0
        let dynamicHeight = CGFloat(level * falloff) * maxAdditionalHeight
        return baseHeight + dynamicHeight
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(
                LinearGradient(
                    colors: [Theme.brandTint, Theme.brandTint.opacity(0.5)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 3, height: height)
            .animation(Theme.springQuick, value: height)
    }
}
