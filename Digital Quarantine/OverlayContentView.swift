import SwiftUI

/// A SwiftUI view displayed on the full-screen overlay during eye rest breaks.
/// It shows a countdown timer and a random instruction.
struct OverlayContentView: View {
    /// Observes the `EyeRestManager` for changes in countdown and instruction text.
    @ObservedObject var eyeRestManager: EyeRestManager
    /// The size of the screen, passed from `EyeRestManager`, used to explicitly frame the view.
    let viewSize: CGSize

    var body: some View {
        ZStack {
            // Ensures the background is black and ignores safe areas, covering the entire screen.
            Color.black.edgesIgnoringSafeArea(.all)

            VStack {
                Spacer() // Pushes content towards the center/top.

                Text("Time to rest your eyes!")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding(.bottom, 20)

                // Displays the current eye rest instruction.
                Text(eyeRestManager.currentInstruction)
                    .font(.title2)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)

                // Displays the remaining countdown seconds.
                Text("Remaining: \(eyeRestManager.currentCountdown) seconds")
                    .font(.system(size: 60, weight: .bold, design: .monospaced))
                    .foregroundColor(.green)
                    // Adds a smooth animation to the countdown text changes.
                    .animation(.easeInOut, value: eyeRestManager.currentCountdown)

                Spacer() // Pushes content towards the center/bottom.
            }
        }
        // Explicitly sets the frame of the ZStack to match the screen size.
        // This was crucial for ensuring the SwiftUI content properly filled the NSWindow.
        .frame(width: viewSize.width, height: viewSize.height)
        // Adds an additional black background layer for robustness,
        // ensuring no transparency issues.
        .background(Color.black)
    }
}
