import SwiftUI

enum DecorationColor: String, CaseIterable, Identifiable {
    case white
    case black
    case red
    case blue
    case gold

    var id: Self { self }
    var title: String { rawValue.capitalized }

    var color: Color {
        switch self {
        case .white: .white
        case .black: .black
        case .red: Color(red: 0.86, green: 0.12, blue: 0.16)
        case .blue: Color(red: 0.10, green: 0.38, blue: 0.82)
        case .gold: Color(red: 0.88, green: 0.66, blue: 0.12)
        }
    }

    var cgColor: CGColor {
        switch self {
        case .white: CGColor(red: 1, green: 1, blue: 1, alpha: 1)
        case .black: CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        case .red: CGColor(red: 0.86, green: 0.12, blue: 0.16, alpha: 1)
        case .blue: CGColor(red: 0.10, green: 0.38, blue: 0.82, alpha: 1)
        case .gold: CGColor(red: 0.88, green: 0.66, blue: 0.12, alpha: 1)
        }
    }
}

enum TextDecorationStyle: String, CaseIterable, Identifiable {
    case clean = "Clean"
    case shadow = "Shadow"
    case outline = "Outline"
    case badge = "Badge"

    var id: Self { self }
}

enum PhotoFrameStyle: String, CaseIterable, Identifiable {
    case none = "None"
    case classic = "Classic"
    case double = "Double"
    case rounded = "Rounded"
    case film = "Film"
    case polaroid = "Polaroid"

    var id: Self { self }
}

struct DecorationSettings {
    var text = ""
    var fontName = "HelveticaNeue-Bold"
    var textSize: CGFloat = 0.08
    var textColor = DecorationColor.white
    var customTextRed = 1.0
    var customTextGreen = 1.0
    var customTextBlue = 1.0
    var usesCustomTextColor = false
    var textOpacity = 1.0
    var textRotation = 0.0
    var textX: CGFloat = 0.5
    var textY: CGFloat = 0.82
    var textBoxWidth: CGFloat = 0.72
    var textStyle = TextDecorationStyle.shadow

    var frameStyle = PhotoFrameStyle.none
    var frameColor = DecorationColor.white
    var customFrameRed = 1.0
    var customFrameGreen = 1.0
    var customFrameBlue = 1.0
    var usesCustomFrameColor = false
    var frameWidth: CGFloat = 0.025
    var frameOpacity = 1.0
    var remoteFrameID: String?

    var hasText: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var hasFrame: Bool {
        frameStyle != .none || remoteFrameID != nil
    }

    var hasDecorations: Bool { hasText || hasFrame }

    var resolvedTextColor: Color {
        usesCustomTextColor
            ? Color(red: customTextRed, green: customTextGreen, blue: customTextBlue)
            : textColor.color
    }

    var resolvedTextCGColor: CGColor {
        usesCustomTextColor
            ? CGColor(red: customTextRed, green: customTextGreen, blue: customTextBlue, alpha: 1)
            : textColor.cgColor
    }

    var resolvedFrameColor: Color {
        usesCustomFrameColor
            ? Color(red: customFrameRed, green: customFrameGreen, blue: customFrameBlue)
            : frameColor.color
    }

    var resolvedFrameCGColor: CGColor {
        usesCustomFrameColor
            ? CGColor(red: customFrameRed, green: customFrameGreen, blue: customFrameBlue, alpha: 1)
            : frameColor.cgColor
    }
}

struct DecorationOverlay: View {
    let settings: DecorationSettings
    let remoteFrame: Image?

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                frame(in: size)
                text(in: size)
            }
        }
        .clipped()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func frame(in size: CGSize) -> some View {
        let width = max(1, min(size.width, size.height) * settings.frameWidth)
        let color = settings.resolvedFrameColor.opacity(settings.frameOpacity)

        switch settings.frameStyle {
        case .none:
            EmptyView()
        case .classic:
            Rectangle().strokeBorder(color, lineWidth: width)
        case .double:
            ZStack {
                Rectangle().strokeBorder(color, lineWidth: width)
                Rectangle().inset(by: width * 1.8).strokeBorder(color, lineWidth: max(1, width * 0.35))
            }
        case .rounded:
            RoundedRectangle(cornerRadius: width * 2.2).strokeBorder(color, lineWidth: width)
        case .film:
            Rectangle().strokeBorder(.black.opacity(settings.frameOpacity), lineWidth: width * 2.2)
        case .polaroid:
            PolaroidFrameShape(bottomScale: 2.6)
                .fill(color)
                .padding(0)
                .mask(PolaroidFrameMask(width: width))
        }

        if let remoteFrame {
            remoteFrame
                .resizable()
                .frame(width: size.width, height: size.height)
                .opacity(settings.frameOpacity)
        }
    }

    @ViewBuilder
    private func text(in size: CGSize) -> some View {
        if settings.hasText {
            let fontSize = max(8, min(size.width, size.height) * settings.textSize)
            Text(settings.text)
                .font(.custom(settings.fontName, size: fontSize))
                .foregroundStyle(settings.resolvedTextColor.opacity(settings.textOpacity))
                .multilineTextAlignment(.center)
                .frame(width: size.width * settings.textBoxWidth)
                .padding(settings.textStyle == .badge ? fontSize * 0.22 : 0)
                .background {
                    if settings.textStyle == .badge {
                        RoundedRectangle(cornerRadius: fontSize * 0.18)
                            .fill(.black.opacity(0.58 * settings.textOpacity))
                    }
                }
                .shadow(
                    color: settings.textStyle == .shadow ? .black.opacity(0.8 * settings.textOpacity) : .clear,
                    radius: fontSize * 0.08,
                    x: fontSize * 0.04,
                    y: fontSize * 0.04
                )
                .overlay {
                    if settings.textStyle == .outline {
                        Text(settings.text)
                            .font(.custom(settings.fontName, size: fontSize))
                            .foregroundStyle(.clear)
                            .shadow(color: .black.opacity(settings.textOpacity), radius: 1)
                    }
                }
                .rotationEffect(.degrees(settings.textRotation))
                .position(x: size.width * settings.textX, y: size.height * settings.textY)
        }
    }
}

struct InteractiveDecorationOverlay: View {
    @Binding var settings: DecorationSettings
    let remoteFrame: Image?

    @State private var moveStart: CGPoint?
    @State private var resizeStart: (width: CGFloat, size: CGFloat)?
    @State private var widthStart: CGFloat?

    var body: some View {
        GeometryReader { proxy in
            let canvasSize = proxy.size

            DecorationOverlay(settings: frameOnlySettings, remoteFrame: remoteFrame)

            if settings.hasText {
                editableText(in: canvasSize)
            }
        }
        .clipped()
    }

    private var frameOnlySettings: DecorationSettings {
        var value = settings
        value.text = ""
        return value
    }

    private func editableText(in canvasSize: CGSize) -> some View {
        let minimumDimension = min(canvasSize.width, canvasSize.height)
        let fontSize = max(8, minimumDimension * settings.textSize)
        let boxWidth = max(70, canvasSize.width * settings.textBoxWidth)

        return Text(settings.text)
            .font(.custom(settings.fontName, size: fontSize))
            .foregroundStyle(settings.resolvedTextColor.opacity(settings.textOpacity))
            .multilineTextAlignment(.center)
            .frame(width: boxWidth)
            .padding(fontSize * 0.2)
            .background {
                if settings.textStyle == .badge {
                    RoundedRectangle(cornerRadius: fontSize * 0.18)
                        .fill(.black.opacity(0.58 * settings.textOpacity))
                }
            }
            .shadow(
                color: settings.textStyle == .shadow ? .black.opacity(0.8 * settings.textOpacity) : .clear,
                radius: fontSize * 0.08,
                x: fontSize * 0.04,
                y: fontSize * 0.04
            )
            .overlay {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(.white, style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
                    .shadow(color: .black.opacity(0.8), radius: 1)
            }
            .overlay(alignment: .trailing) {
                widthHandle(canvasSize: canvasSize)
                    .offset(x: 12)
            }
            .overlay(alignment: .bottomTrailing) {
                resizeHandle(canvasSize: canvasSize)
                    .offset(x: 12, y: 12)
            }
            .overlay(alignment: .top) {
                rotationHandle(canvasSize: canvasSize)
                    .offset(y: -38)
            }
            .rotationEffect(.degrees(settings.textRotation))
            .position(
                x: canvasSize.width * settings.textX,
                y: canvasSize.height * settings.textY
            )
            .contentShape(Rectangle())
            .gesture(moveGesture(canvasSize: canvasSize))
    }

    private func moveGesture(canvasSize: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                if moveStart == nil {
                    moveStart = CGPoint(x: settings.textX, y: settings.textY)
                }
                guard let moveStart else { return }
                settings.textX = min(0.98, max(0.02, moveStart.x + value.translation.width / canvasSize.width))
                settings.textY = min(0.98, max(0.02, moveStart.y + value.translation.height / canvasSize.height))
            }
            .onEnded { _ in moveStart = nil }
    }

    private func widthHandle(canvasSize: CGSize) -> some View {
        Circle()
            .fill(.white)
            .overlay { Circle().stroke(.black.opacity(0.7), lineWidth: 1) }
            .frame(width: 18, height: 18)
            .contentShape(Circle().inset(by: -10))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if widthStart == nil { widthStart = settings.textBoxWidth }
                        guard let widthStart else { return }
                        settings.textBoxWidth = min(0.95, max(0.15, widthStart + value.translation.width / canvasSize.width))
                    }
                    .onEnded { _ in widthStart = nil }
            )
            .accessibilityLabel("Resize text box width")
    }

    private func resizeHandle(canvasSize: CGSize) -> some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(.white)
            .overlay { RoundedRectangle(cornerRadius: 3).stroke(.black.opacity(0.7), lineWidth: 1) }
            .frame(width: 18, height: 18)
            .contentShape(Rectangle().inset(by: -10))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if resizeStart == nil {
                            resizeStart = (settings.textBoxWidth, settings.textSize)
                        }
                        guard let resizeStart else { return }
                        let widthChange = value.translation.width / canvasSize.width
                        let sizeChange = value.translation.height / min(canvasSize.width, canvasSize.height)
                        settings.textBoxWidth = min(0.95, max(0.15, resizeStart.width + widthChange))
                        settings.textSize = min(0.25, max(0.025, resizeStart.size + sizeChange))
                    }
                    .onEnded { _ in resizeStart = nil }
            )
            .accessibilityLabel("Scale text box")
    }

    private func rotationHandle(canvasSize: CGSize) -> some View {
        VStack(spacing: 0) {
            Circle()
                .fill(.blue)
                .overlay { Circle().stroke(.white, lineWidth: 2) }
                .frame(width: 20, height: 20)
            Rectangle()
                .fill(.white)
                .frame(width: 1, height: 18)
        }
        .contentShape(Rectangle().inset(by: -8))
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .named("decorationCanvas"))
                .onChanged { value in
                    let center = CGPoint(
                        x: canvasSize.width * settings.textX,
                        y: canvasSize.height * settings.textY
                    )
                    let deltaX = value.location.x - center.x
                    let deltaY = value.location.y - center.y
                    settings.textRotation = atan2(deltaY, deltaX) * 180 / .pi + 90
                }
        )
        .accessibilityLabel("Rotate text box")
    }
}

private struct PolaroidFrameShape: Shape {
    let bottomScale: CGFloat

    func path(in rect: CGRect) -> Path {
        Path(rect)
    }
}

private struct PolaroidFrameMask: View {
    let width: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            Rectangle().frame(height: width)
            HStack(spacing: 0) {
                Rectangle().frame(width: width)
                Color.clear
                Rectangle().frame(width: width)
            }
            Rectangle().frame(height: width * 2.6)
        }
    }
}
