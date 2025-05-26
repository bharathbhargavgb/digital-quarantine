import SwiftUI

/// A SwiftUI view displayed on the full-screen overlay during eye rest breaks.
/// It shows a countdown timer and a random instruction, adapting to the overlay's phase.
struct OverlayContentView: View {
    /// Observes the `EyeRestManager` for changes in countdown, instruction text, and overlay phase.
    @ObservedObject var eyeRestManager: EyeRestManager
    /// The size of the screen, passed from `EyeRestManager`, used to explicitly frame the view.
    let viewSize: CGSize

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            if eyeRestManager.overlayPhase == .resting {
                VStack {
                    Spacer() // Pushes content towards the center/top.

                    Text("Time to rest your eyes!")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                        .padding(.bottom, 20)

                    Text(eyeRestManager.currentInstruction)
                        .font(.title2)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.bottom, 40)

                    Text("Remaining: \(eyeRestManager.currentCountdown) seconds")
                        .font(.system(size: 60, weight: .bold, design: .monospaced))
                        .foregroundColor(.green)
                        // Adds a smooth animation to the countdown text changes.
                        .animation(.easeInOut, value: eyeRestManager.currentCountdown)

                    Spacer() // Pushes content towards the center/bottom.
                }
            }
        }
        .frame(width: viewSize.width, height: viewSize.height)
        .background(Color.black)
    }
}
