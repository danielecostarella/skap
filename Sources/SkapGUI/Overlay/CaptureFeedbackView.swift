import AppKit
import SkapCore
import SwiftUI

struct CaptureFeedbackView: View {
    let image: CapturedImage
    let message: String

    var body: some View {
        HStack(spacing: 12) {
            Image(nsImage: NSImage(cgImage: image.cgImage, size: .zero))
                .resizable()
                .scaledToFill()
                .frame(width: 72, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(.white.opacity(0.18), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text("Copied")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(width: 260, height: 88)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.24), radius: 18, y: 8)
        .padding(8)
    }
}
