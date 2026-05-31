import SwiftUI

struct AreaSelectionView: View {
    let onSelected: @MainActor (CGRect) -> Void
    let onCancel: @MainActor () -> Void

    @State private var startPoint: CGPoint?
    @State private var currentPoint: CGPoint?

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                Color.black.opacity(0.28)
                    .ignoresSafeArea()

                if let selectionRect {
                    Rectangle()
                        .fill(.clear)
                        .background(
                            Rectangle()
                                .fill(Color.white.opacity(0.08))
                        )
                        .overlay(
                            Rectangle()
                                .stroke(Color.white, lineWidth: 1.5)
                        )
                        .frame(width: selectionRect.width, height: selectionRect.height)
                        .position(x: selectionRect.midX, y: selectionRect.midY)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 1, coordinateSpace: .local)
                    .onChanged { value in
                        if startPoint == nil {
                            startPoint = value.startLocation
                        }
                        currentPoint = value.location
                    }
                    .onEnded { _ in
                        guard let rect = selectionRect else {
                            onCancel()
                            return
                        }

                        let boundedRect = rect.intersection(
                            CGRect(origin: .zero, size: proxy.size)
                        )
                        onSelected(boundedRect)
                    }
            )
            .onExitCommand {
                onCancel()
            }
        }
    }

    private var selectionRect: CGRect? {
        guard let startPoint, let currentPoint else {
            return nil
        }

        return CGRect(
            x: min(startPoint.x, currentPoint.x),
            y: min(startPoint.y, currentPoint.y),
            width: abs(currentPoint.x - startPoint.x),
            height: abs(currentPoint.y - startPoint.y)
        )
    }
}
