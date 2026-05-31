import AppKit
import SkapCore
import SwiftUI

struct AnnotationEditorView: View {
    let baseImage: CGImage
    let onDone: (CGImage) -> Void
    let onCancel: () -> Void

    @State private var elements: [AnnotationElement] = []
    @State private var selectedTool: AnnotationTool = .arrow
    @State private var dragStart: CGPoint?
    @State private var dragCurrent: CGPoint?
    @State private var textInputPosition: CGPoint?
    @State private var pendingText: String = ""
    @State private var canvasSize: CGSize = .zero

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            canvas
        }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: 2) {
            ForEach(AnnotationTool.allCases) { tool in
                Button {
                    selectedTool = tool
                } label: {
                    Image(systemName: symbolName(for: tool))
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.borderless)
                .background(
                    selectedTool == tool
                        ? Color.accentColor.opacity(0.15)
                        : Color.clear,
                    in: RoundedRectangle(cornerRadius: 5)
                )
                .help(toolLabel(for: tool))
            }

            Divider()
                .frame(height: 20)
                .padding(.horizontal, 4)

            Button {
                if !elements.isEmpty { elements.removeLast() }
            } label: {
                Image(systemName: "arrow.uturn.backward")
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.borderless)
            .disabled(elements.isEmpty)
            .help("Undo")

            Spacer()

            Button("Cancel", action: onCancel)
                .keyboardShortcut(.cancelAction)

            Button("Done") {
                commitDone()
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Canvas

    private var canvas: some View {
        GeometryReader { geo in
            let imageAspect = CGFloat(baseImage.width) / CGFloat(baseImage.height)
            let viewAspect = geo.size.width / geo.size.height
            let displaySize = imageAspect > viewAspect
                ? CGSize(width: geo.size.width, height: geo.size.width / imageAspect)
                : CGSize(width: geo.size.height * imageAspect, height: geo.size.height)

            ZStack {
                Color(nsColor: .windowBackgroundColor)

                Image(nsImage: NSImage(cgImage: baseImage, size: .zero))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: displaySize.width, height: displaySize.height)

                Canvas { context, size in
                    drawElements(context: &context, in: size)
                }
                .frame(width: displaySize.width, height: displaySize.height)
                .contentShape(Rectangle())
                .gesture(drawGesture(canvasSize: displaySize))

                if let pos = textInputPosition {
                    textInputOverlay(at: pos, in: displaySize)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onChange(of: displaySize) { _, new in
                canvasSize = new
            }
            .onAppear {
                canvasSize = displaySize
            }
        }
    }

    // MARK: - Drawing

    private func drawElements(context: inout GraphicsContext, in size: CGSize) {
        for element in elements {
            drawElement(element, context: &context)
        }

        if let start = dragStart, let current = dragCurrent, selectedTool != .text {
            let inProgress = makeElement(from: start, to: current)
            drawElement(inProgress, context: &context)
        }
    }

    private func drawElement(_ element: AnnotationElement, context: inout GraphicsContext) {
        switch element.tool {
        case .arrow:
            let start = element.frame.origin
            let end = CGPoint(x: start.x + element.frame.size.width, y: start.y + element.frame.size.height)
            drawArrow(from: start, to: end, context: &context)

        case .rectangle:
            let path = Path(element.frame.standardized)
            context.stroke(path, with: .color(.red), lineWidth: 2.5)

        case .ellipse:
            let path = Path(ellipseIn: element.frame.standardized)
            context.stroke(path, with: .color(.red), lineWidth: 2.5)

        case .highlight:
            let path = Path(element.frame.standardized)
            context.fill(path, with: .color(.yellow.opacity(0.4)))

        case .text:
            if let text = element.text, !text.isEmpty {
                context.draw(
                    Text(text)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.red),
                    at: CGPoint(x: element.frame.minX, y: element.frame.minY),
                    anchor: .topLeading
                )
            }

        case .redact:
            // Show a semi-transparent dark fill as preview (actual blur applied on render)
            let path = Path(element.frame.standardized)
            context.fill(path, with: .color(.black.opacity(0.5)))
        }
    }

    private func drawArrow(from start: CGPoint, to end: CGPoint, context: inout GraphicsContext) {
        var path = Path()
        path.move(to: start)
        path.addLine(to: end)
        context.stroke(path, with: .color(.red), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))

        let angle = atan2(end.y - start.y, end.x - start.x)
        let headLength: CGFloat = 14
        let headAngle: CGFloat = .pi / 6

        var head = Path()
        head.move(to: end)
        head.addLine(to: CGPoint(x: end.x - headLength * cos(angle - headAngle),
                                  y: end.y - headLength * sin(angle - headAngle)))
        head.move(to: end)
        head.addLine(to: CGPoint(x: end.x - headLength * cos(angle + headAngle),
                                  y: end.y - headLength * sin(angle + headAngle)))
        context.stroke(head, with: .color(.red), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
    }

    // MARK: - Gesture

    private func drawGesture(canvasSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if dragStart == nil { dragStart = value.startLocation }
                dragCurrent = value.location
            }
            .onEnded { value in
                guard let start = dragStart else { return }
                let end = value.location

                if selectedTool == .text {
                    textInputPosition = start
                } else {
                    let element = makeElement(from: start, to: end)
                    if abs(element.frame.size.width) > 2 || abs(element.frame.size.height) > 2 {
                        elements.append(element)
                    }
                }
                dragStart = nil
                dragCurrent = nil
            }
    }

    private func makeElement(from start: CGPoint, to end: CGPoint) -> AnnotationElement {
        // For arrow: preserve direction using raw (possibly negative) size
        if selectedTool == .arrow {
            return AnnotationElement(
                tool: .arrow,
                frame: CGRect(origin: start, size: CGSize(width: end.x - start.x, height: end.y - start.y))
            )
        }
        // For shapes: use standardized rect
        return AnnotationElement(
            tool: selectedTool,
            frame: CGRect(x: min(start.x, end.x), y: min(start.y, end.y),
                          width: abs(end.x - start.x), height: abs(end.y - start.y)),
            redactionStyle: selectedTool == .redact ? .pixelate : nil
        )
    }

    // MARK: - Text input

    @ViewBuilder
    private func textInputOverlay(at position: CGPoint, in canvasSize: CGSize) -> some View {
        TextField("Type text…", text: $pendingText)
            .textFieldStyle(.plain)
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(.red)
            .frame(width: 200)
            .position(x: min(position.x + 100, canvasSize.width - 100), y: position.y)
            .onSubmit {
                commitText(at: position)
            }
    }

    private func commitText(at position: CGPoint) {
        if !pendingText.isEmpty {
            elements.append(AnnotationElement(
                tool: .text,
                frame: CGRect(origin: position, size: .zero),
                text: pendingText
            ))
        }
        pendingText = ""
        textInputPosition = nil
    }

    // MARK: - Done

    private func commitDone() {
        let viewSize = canvasSize.width > 0 && canvasSize.height > 0
            ? canvasSize
            : CGSize(width: CGFloat(baseImage.width), height: CGFloat(baseImage.height))

        let rendered = AnnotationRenderer().render(elements: elements, onto: baseImage, viewSize: viewSize)
        onDone(rendered ?? baseImage)
    }

    // MARK: - Helpers

    private func symbolName(for tool: AnnotationTool) -> String {
        switch tool {
        case .arrow:     "arrow.up.right"
        case .rectangle: "rectangle"
        case .ellipse:   "circle"
        case .text:      "textformat"
        case .redact:    "eye.slash"
        case .highlight: "highlighter"
        }
    }

    private func toolLabel(for tool: AnnotationTool) -> String {
        switch tool {
        case .arrow:     "Arrow"
        case .rectangle: "Rectangle"
        case .ellipse:   "Ellipse"
        case .text:      "Text"
        case .redact:    "Redact"
        case .highlight: "Highlight"
        }
    }
}
