import Combine
import SwiftUI

/// Loops through demonstration frames with a crossfade, so a pair of
/// start/end position images reads as a continuous movement demo.
struct ExerciseAnimationView: View {
    let frames: [String]
    var height: CGFloat = 220

    @State private var frameIndex = 0

    private let timer = Timer.publish(every: 1.2, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            ForEach(Array(frames.enumerated()), id: \.offset) { index, name in
                Image(name)
                    .resizable()
                    .scaledToFit()
                    .opacity(index == frameIndex ? 1 : 0)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .padding(Spacing.s3)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .onReceive(timer) { _ in
            guard frames.count > 1 else { return }
            withAnimation(.easeInOut(duration: 0.45)) {
                frameIndex = (frameIndex + 1) % frames.count
            }
        }
    }
}
