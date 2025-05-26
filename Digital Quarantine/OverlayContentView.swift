import SwiftUI

struct OverlayContentView: View {
    @ObservedObject var eyeRestManager: EyeRestManager
    let viewSize: CGSize // <--- NEW PROPERTY: To receive the screen size

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all) // Keep this, as it's the standard
            VStack {
                Spacer()

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
                    .animation(.easeInOut, value: eyeRestManager.currentCountdown)

                Spacer()
            }
        }
        // <--- NEW MODIFIERS: Explicitly set the frame and add another background layer
        .frame(width: viewSize.width, height: viewSize.height) // Force the ZStack to fill the passed size
        .background(Color.black) // Add another background layer here
    }
}
