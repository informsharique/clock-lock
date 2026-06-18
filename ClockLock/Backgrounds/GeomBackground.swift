import SwiftUI

/// Geometric — slowly rotating hexagonal tessellation with animated hue fills.
/// Performance: Driven by display-sync'd TimelineView (no Timer.publish, no @State diffing).
/// Hex grid positions and per-cell hue offsets are cached on size changes.
struct GeomBackground: View {
    // Cached grid data: (position, hueContribution, opacityBase) per cell
    // Built once when the size changes, never reallocated during frames.
    @State private var gridCells: [GridCell] = []
    @State private var cachedSize: CGSize = .zero

    struct GridCell {
        let cx: Double
        let cy: Double
        let hueContrib: Double   // angle+dist contribution — static
        let fillOpacity: Double  // static per-cell fill opacity
        let strokeOpacity: Double
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { ctx, size in
                if cachedSize != size {
                    DispatchQueue.main.async {
                        buildGrid(size: size)
                        cachedSize = size
                    }
                }
                
                let time = timeline.date.timeIntervalSinceReferenceDate
                let rotation = (time * 0.09).truncatingRemainder(dividingBy: .pi * 2)
                let hueOffset = (time * 0.018).truncatingRemainder(dividingBy: 1)
                
                drawGeom(ctx: ctx, size: size, rotation: rotation, hueOffset: hueOffset)
            }
        }
        .ignoresSafeArea()
    }

    private func buildGrid(size: CGSize) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let hexSize: Double = min(size.width, size.height) * 0.065
        let hexW = hexSize * 2
        let hexH = hexSize * sqrt(3.0)
        let cols = Int(size.width  / (hexW * 0.75)) + 3
        let rows = Int(size.height / hexH) + 3
        let maxDist = sqrt(center.x * center.x + center.y * center.y)

        var cells: [GridCell] = []
        cells.reserveCapacity(rows * cols)

        for row in -1..<rows {
            for col in -1..<cols {
                let offsetX = (row % 2 == 0) ? 0.0 : hexW * 0.75 * 0.5
                let cx = Double(col) * hexW * 0.75 + offsetX
                let cy = Double(row) * hexH

                let dx = cx - center.x
                let dy = cy - center.y
                let dist = sqrt(dx * dx + dy * dy)
                let normDist = dist / maxDist
                let angle = atan2(dy, dx)
                let hueContrib = (angle + .pi) / (.pi * 2) * 0.4 + normDist * 0.3

                cells.append(GridCell(
                    cx: cx, cy: cy,
                    hueContrib: hueContrib,
                    fillOpacity: 0.18 + (1 - normDist) * 0.12,
                    strokeOpacity: 0.35 + (1 - normDist) * 0.20
                ))
            }
        }
        gridCells = cells
    }

    private func drawGeom(ctx: GraphicsContext, size: CGSize, rotation: Double, hueOffset: Double) {
        // Dark solid base
        let baseHue = (hueOffset + 0.64).truncatingRemainder(dividingBy: 1)
        ctx.fill(Path(CGRect(origin: .zero, size: size)),
                 with: .color(Color(hue: baseHue, saturation: 0.85, brightness: 0.06)))

        let hexSize: Double = min(size.width, size.height) * 0.065

        for cell in gridCells {
            let hue = (hueOffset + cell.hueContrib).truncatingRemainder(dividingBy: 1)
            let hexPath = hexPath(cx: cell.cx, cy: cell.cy, radius: hexSize - 1.5, rot: rotation)
            let color = Color(hue: hue, saturation: 0.8, brightness: 0.65)

            var fillCtx = ctx; fillCtx.opacity = cell.fillOpacity
            fillCtx.fill(hexPath, with: .color(color))

            var strokeCtx = ctx; strokeCtx.opacity = cell.strokeOpacity
            strokeCtx.stroke(hexPath,
                             with: .color(Color(hue: hue, saturation: 0.6, brightness: 0.85)),
                             lineWidth: 0.8)
        }

        // Central glow
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let glowR = min(size.width, size.height) * 0.38
        var gc = ctx; gc.opacity = 0.14; gc.blendMode = .screen
        gc.fill(Path(ellipseIn: CGRect(x: center.x - glowR, y: center.y - glowR,
                                        width: glowR * 2, height: glowR * 2)),
                with: .radialGradient(
                    Gradient(colors: [Color(hue: hueOffset, saturation: 0.7, brightness: 0.9), .clear]),
                    center: center, startRadius: 0, endRadius: glowR
                ))
    }

    private func hexPath(cx: Double, cy: Double, radius: Double, rot: Double) -> Path {
        var p = Path()
        for i in 0..<6 {
            let a = Double(i) * .pi / 3 + rot
            let pt = CGPoint(x: cx + radius * cos(a), y: cy + radius * sin(a))
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}
