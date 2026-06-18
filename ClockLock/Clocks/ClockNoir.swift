import SwiftUI
import Foundation

/// "Void" — A premium squircle (heavy rounded-rectangle) shaped watch face.
/// Dark gunmetal case with a deep blue-violet gradient dial.
/// White applied indices, gradient hands, thin orange seconds.
struct ClockVoid: View {
    let date: Date

    private var angles: (h: Double, m: Double, s: Double) {
        let cal = Calendar.current
        let h = Double(cal.component(.hour, from: date)).truncatingRemainder(dividingBy: 12)
        let m = Double(cal.component(.minute, from: date))
        let s = Double(cal.component(.second, from: date))
        let ns = Double(cal.component(.nanosecond, from: date)) / 1_000_000_000
        let sf = s + ns
        let mf = m + sf / 60.0
        let hf = h + mf / 60.0
        return (
            h: hf / 12.0 * 2 * .pi - .pi / 2,
            m: mf / 60.0 * 2 * .pi - .pi / 2,
            s: sf / 60.0 * 2 * .pi - .pi / 2
        )
    }

    var body: some View {
        GeometryReader { geo in
            let size: CGFloat = min(geo.size.width, geo.size.height)
            voidDial(size: size)
        }
    }

    @ViewBuilder
    private func voidDial(size: CGFloat) -> some View {
        let cornerR: CGFloat = size * 0.22  // squircle corner radius

        ZStack {
            // Gunmetal case — angular gradient for brushed metal look
            RoundedRectangle(cornerRadius: cornerR)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color(white: 0.30), location: 0.00),
                            .init(color: Color(white: 0.16), location: 0.35),
                            .init(color: Color(white: 0.10), location: 0.65),
                            .init(color: Color(white: 0.20), location: 1.00),
                        ],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )

            // Polished bezel border
            RoundedRectangle(cornerRadius: cornerR)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color(white: 0.55), Color(white: 0.18), Color(white: 0.50), Color(white: 0.15)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: size * 0.012
                )

            // Deep blue-violet dial inset
            RoundedRectangle(cornerRadius: cornerR * 0.78)
                .fill(
                    RadialGradient(
                        stops: [
                            .init(color: Color(red: 0.10, green: 0.08, blue: 0.35), location: 0.00),
                            .init(color: Color(red: 0.06, green: 0.04, blue: 0.28), location: 0.45),
                            .init(color: Color(red: 0.03, green: 0.01, blue: 0.18), location: 0.80),
                            .init(color: Color(red: 0.01, green: 0.01, blue: 0.10), location: 1.00),
                        ],
                        center: .init(x: 0.4, y: 0.35),
                        startRadius: 0,
                        endRadius: size * 0.50
                    )
                )
                .padding(size * 0.048)

            // Subtle dial highlight (glass gloss)
            RoundedRectangle(cornerRadius: cornerR * 0.78)
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.06), Color.white.opacity(0)],
                        center: .init(x: 0.35, y: 0.25),
                        startRadius: 0, endRadius: size * 0.45
                    )
                )
                .padding(size * 0.048)

            // Canvas: indices + hands, clipped to dial shape
            Canvas { ctx, cSize in
                renderVoid(ctx: ctx, size: cSize)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerR * 0.78))
            .padding(size * 0.048)
        }
    }

    private func renderVoid(ctx: GraphicsContext, size: CGSize) {
        let c = CGPoint(x: round(size.width / 2), y: round(size.height / 2))
        let r: CGFloat = min(size.width, size.height) / 2
        let ang = angles

        // Applied indices
        drawVoidIndices(ctx: ctx, center: c, radius: r)

        // Hour hand — thick white gradient baton
        drawVoidHand(ctx: ctx, center: c, angle: ang.h,
                     length: r * 0.50, tail: r * 0.12, width: r * 0.038,
                     color: Color.white)

        // Minute hand — slimmer
        drawVoidHand(ctx: ctx, center: c, angle: ang.m,
                     length: r * 0.72, tail: r * 0.14, width: r * 0.022,
                     color: Color.white)

        // Seconds — thin bright orange
        let orange = Color(red: 0.95, green: 0.42, blue: 0.08)
        var sp = Path()
        sp.move(to: CGPoint(x: c.x - r * 0.18 * CGFloat(cos(ang.s)),
                             y: c.y - r * 0.18 * CGFloat(sin(ang.s))))
        sp.addLine(to: CGPoint(x: c.x + r * 0.76 * CGFloat(cos(ang.s)),
                                y: c.y + r * 0.76 * CGFloat(sin(ang.s))))
        ctx.stroke(sp, with: .color(orange), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))

        // Center medallion
        let med: CGFloat = r * 0.038
        ctx.fill(Path(ellipseIn: CGRect(x: c.x - med, y: c.y - med, width: med * 2, height: med * 2)),
                 with: .radialGradient(Gradient(colors: [Color(white: 0.80), Color(white: 0.38)]),
                                       center: c, startRadius: 0, endRadius: med))
        let medOrange: CGFloat = med * 0.55
        ctx.fill(Path(ellipseIn: CGRect(x: c.x - medOrange, y: c.y - medOrange,
                                         width: medOrange * 2, height: medOrange * 2)),
                 with: .color(orange))
    }

    private func drawVoidIndices(ctx: GraphicsContext, center: CGPoint, radius: CGFloat) {
        for i in 0..<12 {
            let a: Double = Double(i) / 12.0 * 2 * .pi - .pi / 2
            let isQuarter = i % 3 == 0
            let outerR: CGFloat = radius * 0.88
            let len: CGFloat = isQuarter ? radius * 0.12 : radius * 0.06
            let w: CGFloat = isQuarter ? 3.0 : 1.5

            var idx = Path()
            idx.move(to: CGPoint(x: center.x + outerR * CGFloat(cos(a)),
                                  y: center.y + outerR * CGFloat(sin(a))))
            idx.addLine(to: CGPoint(x: center.x + (outerR - len) * CGFloat(cos(a)),
                                     y: center.y + (outerR - len) * CGFloat(sin(a))))

            // Polished index: shadow then highlight
            var sc = ctx; sc.opacity = 0.4
            var sidx = Path()
            sidx.move(to: CGPoint(x: center.x + outerR * CGFloat(cos(a)) + 0.6,
                                   y: center.y + outerR * CGFloat(sin(a)) + 0.6))
            sidx.addLine(to: CGPoint(x: center.x + (outerR - len) * CGFloat(cos(a)) + 0.6,
                                      y: center.y + (outerR - len) * CGFloat(sin(a)) + 0.6))
            sc.stroke(sidx, with: .color(.black), lineWidth: w)
            ctx.stroke(idx, with: .color(Color(white: isQuarter ? 0.95 : 0.75)),
                       style: StrokeStyle(lineWidth: w, lineCap: isQuarter ? .butt : .round))
        }

        // Minor tick dots at 5-minute positions (non-hour)
        for i in 0..<60 {
            if i % 5 == 0 { continue }
            let a: Double = Double(i) / 60.0 * 2 * .pi - .pi / 2
            let dotR: CGFloat = radius * 0.89
            let ds: CGFloat = 1.2
            let dp = CGPoint(x: center.x + dotR * CGFloat(cos(a)), y: center.y + dotR * CGFloat(sin(a)))
            ctx.fill(Path(ellipseIn: CGRect(x: dp.x - ds / 2, y: dp.y - ds / 2, width: ds, height: ds)),
                     with: .color(Color(white: 0.42)))
        }
    }

    private func drawVoidHand(ctx: GraphicsContext, center: CGPoint,
                               angle: Double, length: CGFloat, tail: CGFloat,
                               width: CGFloat, color: Color) {
        let tip = CGPoint(x: center.x + length * CGFloat(cos(angle)),
                          y: center.y + length * CGFloat(sin(angle)))
        let base = CGPoint(x: center.x - tail * CGFloat(cos(angle)),
                           y: center.y - tail * CGFloat(sin(angle)))
        // Drop shadow
        var sp = Path(); sp.move(to: CGPoint(x: base.x + 1, y: base.y + 1))
        sp.addLine(to: CGPoint(x: tip.x + 1, y: tip.y + 1))
        var sc = ctx; sc.opacity = 0.45
        sc.stroke(sp, with: .color(.black), style: StrokeStyle(lineWidth: width, lineCap: .round))
        // Hand body with gentle gradient
        var p = Path(); p.move(to: base); p.addLine(to: tip)
        ctx.stroke(p, with: .linearGradient(
            Gradient(colors: [Color(white: 0.98), Color(white: 0.72)]),
            startPoint: base, endPoint: tip
        ), style: StrokeStyle(lineWidth: width, lineCap: .round))
    }
}
