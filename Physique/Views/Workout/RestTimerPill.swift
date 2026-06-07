import SwiftUI

struct RestTimerPill: View {
    let remaining: Int
    let total: Int
    let onAdjust: (Int) -> Void
    let onSkip: () -> Void
    let onTick: () -> Void

    @State private var showControls = false

    private var fraction: Double {
        guard total > 0 else { return 0 }
        return Double(remaining) / Double(total)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                showControls.toggle()
            } label: {
                HStack(spacing: 9) {
                    // Circular progress
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 3)
                            .frame(width: 26, height: 26)
                        Circle()
                            .trim(from: 0, to: fraction)
                            .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: 26, height: 26)
                            .rotationEffect(.degrees(-90))
                    }

                    Text(TimeFormatter.duration(TimeInterval(remaining)))
                        .font(.system(size: TypeScale.body, weight: .bold))
                        .monospacedDigit()
                }
                .foregroundStyle(.white)
                .padding(.horizontal, Spacing.s4)
                .padding(.vertical, Spacing.s2)
                .background(Color.accent)
                .clipShape(Capsule())
            }

            if showControls {
                HStack(spacing: 6) {
                    restControlButton("-15") { onAdjust(-15) }
                    restControlButton("+15") { onAdjust(15) }
                    restControlButton("Skip") {
                        onSkip()
                        showControls = false
                    }
                }
                .padding(6)
                .background(Color(hex: 0x151518))
                .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .padding(.top, Spacing.s2)
            }
        }
        .onAppear {
            startTimer()
        }
    }

    private func restControlButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: TypeScale.sub, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, Spacing.s3)
                .padding(.vertical, Spacing.s2)
                .background(Color(hex: 0x29292F))
                .clipShape(RoundedRectangle(cornerRadius: Radius.xs))
        }
    }

    private func startTimer() {
        Task { @MainActor in
            while remaining > 0 {
                try? await Task.sleep(for: .seconds(1))
                onTick()
            }
        }
    }
}
