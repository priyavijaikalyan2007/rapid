import SwiftUI

struct CropCanvas: View {
    let photo: LoadedPhoto
    let displayImage: CGImage
    @Binding var normalizedCrop: CGRect
    let aspectRatio: CGFloat
    let passportGuide: PassportGuide?
    @Binding var decoration: DecorationSettings
    let remoteFrame: Image?

    @State private var dragStart = CGRect.zero
    @State private var resizeStart = CGRect.zero

    var body: some View {
        GeometryReader { proxy in
            let bounds = CGRect(origin: .zero, size: proxy.size)
            let imageRect = CropGeometry.aspectFit(content: photo.pixelSize, in: bounds)
            let cropRect = CGRect(
                x: imageRect.minX + normalizedCrop.minX * imageRect.width,
                y: imageRect.minY + normalizedCrop.minY * imageRect.height,
                width: normalizedCrop.width * imageRect.width,
                height: normalizedCrop.height * imageRect.height
            )

            ZStack(alignment: .topLeading) {
                Color(nsColor: .windowBackgroundColor)

                Image(decorative: displayImage, scale: 1, orientation: .up)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: imageRect.width, height: imageRect.height)
                    .position(x: imageRect.midX, y: imageRect.midY)

                Path { path in
                    path.addRect(imageRect)
                    path.addRect(cropRect)
                }
                .fill(.black.opacity(0.58), style: FillStyle(eoFill: true))
                .allowsHitTesting(false)

                Rectangle()
                    .fill(.clear)
                    .overlay {
                        Rectangle().stroke(.white, lineWidth: 2)
                    }
                    .overlay {
                        if passportGuide == nil {
                            RuleOfThirdsGrid()
                                .stroke(.white.opacity(0.55), lineWidth: 1)
                        }
                    }
                    .frame(width: cropRect.width, height: cropRect.height)
                    .position(x: cropRect.midX, y: cropRect.midY)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if dragStart == .zero {
                                    dragStart = normalizedCrop
                                }
                                let translation = CGSize(
                                    width: value.translation.width / imageRect.width,
                                    height: value.translation.height / imageRect.height
                                )
                                let moved = dragStart.offsetBy(dx: translation.width, dy: translation.height)
                                normalizedCrop = CropGeometry.clamp(
                                    moved,
                                    to: CGRect(x: 0, y: 0, width: 1, height: 1)
                                )
                            }
                            .onEnded { _ in
                                dragStart = .zero
                            }
                    )
                    .cursor(.openHand)

                if let passportGuide {
                    PassportGuideOverlay(guide: passportGuide)
                        .frame(width: cropRect.width, height: cropRect.height)
                        .position(x: cropRect.midX, y: cropRect.midY)
                }

                InteractiveDecorationOverlay(settings: $decoration, remoteFrame: remoteFrame)
                    .frame(width: cropRect.width, height: cropRect.height)
                    .position(x: cropRect.midX, y: cropRect.midY)
                    .coordinateSpace(name: "decorationCanvas")

                ForEach(CropCorner.allCases, id: \.self) { corner in
                    resizeHandle(for: corner, cropRect: cropRect, imageRect: imageRect)
                }
            }
        }
        .accessibilityLabel("Photo crop area")
        .accessibilityHint("Drag the crop rectangle to choose the part of the photo to keep.")
    }

    private func resizeHandle(for corner: CropCorner, cropRect: CGRect, imageRect: CGRect) -> some View {
        ZStack {
            Circle()
                .fill(.white)
                .overlay { Circle().stroke(.black.opacity(0.65), lineWidth: 1) }
                .shadow(radius: 1)
                .frame(width: 16, height: 16)
        }
            .frame(width: 36, height: 36)
            .contentShape(Circle())
            .position(corner.point(in: cropRect))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if resizeStart == .zero { resizeStart = normalizedCrop }
                        let translation = CGSize(
                            width: value.translation.width / imageRect.width,
                            height: value.translation.height / imageRect.height
                        )
                        let minimumHeight = max(
                            44 / imageRect.height,
                            44 / (aspectRatio * imageRect.height)
                        )
                        normalizedCrop = CropGeometry.resizedCrop(
                            from: resizeStart,
                            corner: corner,
                            normalizedTranslation: translation,
                            imageSize: photo.pixelSize,
                            aspectRatio: aspectRatio,
                            minimumNormalizedHeight: minimumHeight
                        )
                    }
                    .onEnded { _ in resizeStart = .zero }
            )
            .accessibilityLabel("Resize \(corner.accessibilityName) corner")
            .accessibilityHint("Drag to resize the crop area without changing its aspect ratio.")
    }
}

private struct RuleOfThirdsGrid: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        for fraction in [CGFloat(1) / 3, CGFloat(2) / 3] {
            path.move(to: CGPoint(x: rect.width * fraction, y: 0))
            path.addLine(to: CGPoint(x: rect.width * fraction, y: rect.height))
            path.move(to: CGPoint(x: 0, y: rect.height * fraction))
            path.addLine(to: CGPoint(x: rect.width, y: rect.height * fraction))
        }
        return path
    }
}

private extension View {
    @ViewBuilder
    func cursor(_ cursor: NSCursor) -> some View {
        onHover { isInside in
            if isInside {
                cursor.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

private extension CropCorner {
    func point(in rect: CGRect) -> CGPoint {
        switch self {
        case .topLeft: CGPoint(x: rect.minX, y: rect.minY)
        case .topRight: CGPoint(x: rect.maxX, y: rect.minY)
        case .bottomLeft: CGPoint(x: rect.minX, y: rect.maxY)
        case .bottomRight: CGPoint(x: rect.maxX, y: rect.maxY)
        }
    }

    var accessibilityName: String {
        switch self {
        case .topLeft: "top left"
        case .topRight: "top right"
        case .bottomLeft: "bottom left"
        case .bottomRight: "bottom right"
        }
    }
}
