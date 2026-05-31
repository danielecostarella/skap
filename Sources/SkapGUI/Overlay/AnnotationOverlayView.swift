import SkapCore
import SwiftUI

struct AnnotationOverlayView: View {
    @State private var selectedTool: AnnotationTool = .arrow

    var body: some View {
        HStack(spacing: 8) {
            ForEach(AnnotationTool.allCases) { tool in
                Button {
                    selectedTool = tool
                } label: {
                    Image(systemName: symbolName(for: tool))
                }
                .buttonStyle(.bordered)
                .help(tool.rawValue)
            }
        }
        .padding(8)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func symbolName(for tool: AnnotationTool) -> String {
        switch tool {
        case .arrow:
            "arrow.up.right"
        case .rectangle:
            "rectangle"
        case .ellipse:
            "circle"
        case .text:
            "textformat"
        case .redact:
            "eye.slash"
        case .highlight:
            "highlighter"
        }
    }
}
