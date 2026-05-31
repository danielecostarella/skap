import AppKit
import SkapCore
import SwiftUI

struct PinnedImageView: View {
    let image: CapturedImage

    var body: some View {
        Image(nsImage: NSImage(cgImage: image.cgImage, size: .zero))
            .resizable()
            .scaledToFit()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(radius: 16)
            .padding(8)
    }
}
