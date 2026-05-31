import AppKit
import SkapCore
import SwiftUI

struct PinnedImageView: View {
    let image: CapturedImage

    var body: some View {
        VStack(spacing: 0) {
            Image(nsImage: NSImage(cgImage: image.cgImage, size: .zero))
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(10)
        }
        .background(.regularMaterial)
    }
}
