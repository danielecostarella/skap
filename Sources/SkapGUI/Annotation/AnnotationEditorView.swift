import AppKit
import SkapCore
import SwiftUI

struct AnnotationEditorView: View {
    let baseImage: CGImage
    let onDone: (CGImage) -> Void
    let onCancel: () -> Void

    @State private var elements: [AnnotationElement] = []
    @State private var redoStack: [AnnotationElement] = []
    @State private var selectedTool: AnnotationTool = .arrow
    @State private var selectedColor: AnnotationColor = .red
    @State private var dragStart: CGPoint?
    @State private var dragCurrent: CGPoint?
    @State private var penPoints: [CGPoint] = []
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
                        .frame(width: 26, height: 26)
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

            Divider().frame(height: 20).padding(.horizontal, 4)

            // Color palette
            ForEach(AnnotationColor.allCases, id: \.rawValue) { color in
                Circle()
                    .fill(color.swiftUIColor)
                    .frame(width: 14, height: 14)
                    .overlay(
                        selectedColor == color
                            ? Circle().stroke(Color.primary.opacity(0.8), lineWidth: 1.5)
                            : nil
                    )
                    .onTapGesture { selectedColor = color }
                    .help(color.rawValue.capitalized)
                    .padding(2)
            }

            Divider().frame(height: 20).padding(.horizontal, 4)

            Button {
                undo()
            } label: {
                Image(systemName: "arrow.uturn.backward")
                    .frame(width: 26, height: 26)
            }
            .buttonStyle(.borderless)
            .keyboardShortcut("z", modifiers: .command)
            .disabled(elements.isEmpty)
            .help("Undo")

            Button {
                redo()
            } label: {
                Image(systemName: "arrow.uturn.forward")
                    .frame(width: 26, height: 26)
            }
            .buttonStyle(.borderless)
            .keyboardShortcut("z", modifiers: [.command, .shift])
            .disabled(redoStack.isEmpty)
            .help("Redo")

            Spacer()

            Button("Cancel", action: onCancel)
                .keyboardShortcut(.cancelAction)

            Button("Done") { commitDone() }
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
            .onChange(of: displaySize) { _, new in canvasSize = new }
            .onAppear { canvasSize = displaySize }
        }
    }

    // MARK: - Drawing

    private func drawElements(context: inout GraphicsContext, in size: CGSize) {
        for element in elements {
            drawElement(element, context: &context)
        }

        if selectedTool == .pen, penPoints.count > 1 {
            drawPenPath(penPoints, color: selectedColor, context: &context)
        } else if let start = dragStart, let current = dragCurrent, selectedTool != .text {
            drawElement(makeElement(from: start, to: current), context: &context)
        }
    }

    private func drawElement(_ element: AnnotationElement, context: inout GraphicsContext) {
        switch element.tool {
        case .arrow:
            let start = element.frame.origin
            let end = CGPoint(x: start.x + element.frame.size.width, y: start.y + element.frame.size.height)
            drawArrow(from: start, to: end, color: element.color, context: &context)

        case .rectangle:
            let path = Path(element.frame.standardized)
            context.stroke(path, with: .color(element.color.swiftUIColor), lineWidth: 2.5)

        case .ellipse:
            let path = Path(ellipseIn: element.frame.standardized)
            context.stroke(path, with: .color(element.color.swiftUIColor), lineWidth: 2.5)

        case .highlight:
            let path = Path(element.frame.standardized)
            context.fill(path, with: .color(element.color.swiftUIColor.opacity(0.4)))

        case .pen:
            if let pts = element.points, pts.count > 1 {
                drawPenPath(pts, color: element.color, context: &context)
            }

        case .text:
            if let text = element.text, !text.isEmpty {
                context.draw(
                    Text(text)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(element.color.swiftUIColor),
                    at: CGPoint(x: element.frame.minX, y: element.frame.minY),
                    anchor: .topLeading
                )
            }

        case .redact:
            let path = Path(element.frame.standardized)
            context.fill(path, with: .color(.black.opacity(0.5)))
        }
    }

    private func drawArrow(from start: CGPoint, to end: CGPoint, color: AnnotationColor, context: inout GraphicsContext) {
        var path = Path()
        path.move(to: start)
        path.addLine(to: end)
        context.stroke(path, with: .color(color.swiftUIColor), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))

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
        context.stroke(head, with: .color(color.swiftUIColor), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
    }

    private func drawPenPath(_ points: [CGPoint], color: AnnotationColor, context: inout GraphicsContext) {
        var path = Path()
        path.move(to: points[0])
        for p in points.dropFirst() { path.addLine(to: p) }
        context.stroke(path, with: .color(color.swiftUIColor.opacity(0.4)),
                       style: StrokeStyle(lineWidth: 18, lineCap: .round, lineJoin: .round))
    }

    // MARK: - Gesture

    private func drawGesture(canvasSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if selectedTool == .pen {
                    penPoints.append(value.location)
                } else {
                    if dragStart == nil { dragStart = value.startLocation }
                    dragCurrent = value.location
                }
            }
            .onEnded { value in
                if selectedTool == .pen {
                    if penPoints.count > 1 {
                        commitElement(AnnotationElement(
                            tool: .pen,
                            frame: boundingBox(of: penPoints),
                            color: selectedColor,
                            points: penPoints
                        ))
                    }
                    penPoints = []
                } else {
                    guard let start = dragStart else { return }
                    if selectedTool == .text {
                        textInputPosition = start
                    } else {
                        let element = makeElement(from: start, to: value.location)
                        if abs(element.frame.size.width) > 2 || abs(element.frame.size.height) > 2 {
                            commitElement(element)
                        }
                    }
                    dragStart = nil
                    dragCurrent = nil
                }
            }
    }

    private func makeElement(from start: CGPoint, to end: CGPoint) -> AnnotationElement {
        if selectedTool == .arrow {
            return AnnotationElement(
                tool: .arrow,
                frame: CGRect(origin: start, size: CGSize(width: end.x - start.x, height: end.y - start.y)),
                color: selectedColor
            )
        }
        return AnnotationElement(
            tool: selectedTool,
            frame: CGRect(x: min(start.x, end.x), y: min(start.y, end.y),
                          width: abs(end.x - start.x), height: abs(end.y - start.y)),
            redactionStyle: selectedTool == .redact ? .pixelate : nil,
            color: selectedColor
        )
    }

    private func boundingBox(of points: [CGPoint]) -> CGRect {
        let xs = points.map(\.x), ys = points.map(\.y)
        guard let minX = xs.min(), let minY = ys.min(),
              let maxX = xs.max(), let maxY = ys.max() else { return .zero }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    // MARK: - Text input

    @ViewBuilder
    private func textInputOverlay(at position: CGPoint, in canvasSize: CGSize) -> some View {
        TextField("Type text…", text: $pendingText)
            .textFieldStyle(.plain)
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(selectedColor.swiftUIColor)
            .frame(width: 200)
            .position(textFieldCenter(for: position, in: canvasSize))
            .onSubmit { commitText(at: textAnnotationOrigin(for: position, in: canvasSize)) }
    }

    private func commitText(at position: CGPoint) {
        if !pendingText.isEmpty {
            commitElement(AnnotationElement(
                tool: .text,
                frame: CGRect(origin: position, size: .zero),
                text: pendingText,
                color: selectedColor
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

    private func commitElement(_ element: AnnotationElement) {
        elements.append(element)
        redoStack.removeAll()
    }

    private func undo() {
        guard let element = elements.popLast() else { return }
        redoStack.append(element)
    }

    private func redo() {
        guard let element = redoStack.popLast() else { return }
        elements.append(element)
    }

    // MARK: - Helpers

    private func symbolName(for tool: AnnotationTool) -> String {
        switch tool {
        case .arrow:     "arrow.up.right"
        case .rectangle: "rectangle"
        case .ellipse:   "circle"
        case .text:      "textformat"
        case .pen:       "scribble"
        case .highlight: "highlighter"
        case .redact:    "eye.slash"
        }
    }

    private func toolLabel(for tool: AnnotationTool) -> String {
        switch tool {
        case .arrow:     "Arrow"
        case .rectangle: "Rectangle"
        case .ellipse:   "Ellipse"
        case .text:      "Text"
        case .pen:       "Freehand Highlight"
        case .highlight: "Rectangle Highlight"
        case .redact:    "Redact"
        }
    }

    private func textFieldCenter(for position: CGPoint, in canvasSize: CGSize) -> CGPoint {
        CGPoint(
            x: min(position.x + 100, max(canvasSize.width - 100, 100)),
            y: position.y
        )
    }

    private func textAnnotationOrigin(for position: CGPoint, in canvasSize: CGSize) -> CGPoint {
        let center = textFieldCenter(for: position, in: canvasSize)
        return CGPoint(x: center.x - 100, y: center.y)
    }
}

private extension AnnotationColor {
    var swiftUIColor: Color {
        switch self {
        case .red:    .red
        case .orange: .orange
        case .yellow: .yellow
        case .green:  .green
        case .blue:   .blue
        case .white:  .white
        }
    }
}
