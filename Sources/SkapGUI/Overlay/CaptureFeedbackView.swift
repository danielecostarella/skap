import AppKit
import SkapCore
import SwiftUI

struct CaptureFeedbackView: View {
    let image: CapturedImage?
    let message: String
    let isError: Bool

    var body: some View {
        HStack(spacing: 10) {
            leadingIcon

            VStack(alignment: .leading, spacing: 3) {
                Text(isError ? "Error" : "Copied")
                    .font(.headline)
                    .foregroundStyle(isError ? Color(nsColor: .systemRed) : .primary)

                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
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

    @ViewBuilder
    private var leadingIcon: some View {
        if isError {
            Image(systemName: "exclamationmark.triangle.fill")
                .symbolRenderingMode(.multicolor)
                .font(.title2)
                .frame(width: 40, height: 40)
        } else if let image {
            Image(nsImage: NSImage(cgImage: image.cgImage, size: .zero))
                .resizable()
                .scaledToFill()
                .frame(width: 56, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(.white.opacity(0.18), lineWidth: 1)
                )
        }
    }
}
