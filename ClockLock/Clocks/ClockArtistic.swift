import SwiftUI
import Foundation

/// "Sunrise" — The entire dial is filled with a radial gradient that evokes a sunrise:
/// warm amber-gold at center flowing outward through rose to deep indigo.
/// Ultra-thin white hands with drop-shadow contrast. Minimal embossed hour lines.
struct ClockSunrise: View {
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
            sunriseDial(size: size)
        }
    }

    @ViewBuilder
    private func sunriseDial(size: CGFloat) -> some View {
        ZStack {
            // Sunrise radial gradient fills the entire dial
            Circle()
                .fill(
                    RadialGradient(
                        stops: [
                            .init(color: Color(red: 1.00, green: 0.92, blue: 0.55), location: 0.00), // warm gold
                            .init(color: Color(red: 1.00, green: 0.68, blue: 0.28), location: 0.18), // amber
                            .init(color: Color(red: 0.90, green: 0.35, blue: 0.40), location: 0.38), // coral rose
                            .init(color: Color(red: 0.60, green: 0.15, blue: 0.55), location: 0.60), // violet
                            .init(color: Color(red: 0.12, green: 0.05, blue: 0.45), location: 0.80), // deep indigo
                            .init(color: Color(red: 0.04, green: 0.02, blue: 0.22), location: 1.00), // near black
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.50
                    )
                )

            // Glass-like outer ring
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.35), Color.white.opacity(0.08)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: size * 0.010
                )

            // Canvas: hour lines + hands
            Canvas { ctx, cSize in
                renderSunrise(ctx: ctx, size: cSize)
            }
        }
    }

    private func renderSunrise(ctx: GraphicsContext, size: CGSize) {
        let c = CGPoint(x: round(size.width / 2), y: round(size.height / 2))
        let r: CGFloat = min(size.width, size.height) / 2
        let ang = angles

        // Hour position lines — delicate, embossed look
        for i in 0..<12 {
            let a: Double = Double(i) / 12.0 * 2 * .pi - .pi / 2
            let isQuarter = i % 3 == 0
            let outerR: CGFloat = r * 0.88
            let len: CGFloat = isQuarter ? r * 0.10 : r * 0.055
            let w: CGFloat = isQuarter ? 1.8 : 1.0

            var tick = Path()
            tick.move(to: CGPoint(x: c.x + outerR * CGFloat(cos(a)), y: c.y + outerR * CGFloat(sin(a))))
            tick.addLine(to: CGPoint(x: c.x + (outerR - len) * CGFloat(cos(a)),
                                      y: c.y + (outerR - len) * CGFloat(sin(a))))

            // Shadow line (offset 1px for emboss illusion)
            var shadowCtx = ctx; shadowCtx.opacity = 0.25
            var shadowTick = Path()
            shadowTick.move(to: CGPoint(x: c.x + outerR * CGFloat(cos(a)) + 0.8,
                                         y: c.y + outerR * CGFloat(sin(a)) + 0.8))
            shadowTick.addLine(to: CGPoint(x: c.x + (outerR - len) * CGFloat(cos(a)) + 0.8,
                                            y: c.y + (outerR - len) * CGFloat(sin(a)) + 0.8))
            shadowCtx.stroke(shadowTick, with: .color(.black), lineWidth: w)
            ctx.stroke(tick, with: .color(Color.white.opacity(isQuarter ? 0.90 : 0.65)), lineWidth: w)
        }

        // Minute dots — very small, only at 5-min positions
        for i in 0..<60 {
            if i % 5 == 0 { continue }
            let a: Double = Double(i) / 60.0 * 2 * .pi - .pi / 2
            let dotR: CGFloat = r * 0.90
            let ds: CGFloat = 0.9
            let dp = CGPoint(x: c.x + dotR * CGFloat(cos(a)), y: c.y + dotR * CGFloat(sin(a)))
            ctx.fill(Path(ellipseIn: CGRect(x: dp.x - ds / 2, y: dp.y - ds / 2, width: ds, height: ds)),
                     with: .color(Color.white.opacity(0.35)))
        }

        // Hour hand — wide white with shadow
        drawSunriseHand(ctx: ctx, center: c, angle: ang.h, length: r * 0.50, tail: r * 0.12, width: r * 0.030)

        // Minute hand
        drawSunriseHand(ctx: ctx, center: c, angle: ang.m, length: r * 0.74, tail: r * 0.14, width: r * 0.018)

        // Seconds — ivory with warm golden tip
        drawSunriseSecond(ctx: ctx, center: c, angle: ang.s, radius: r)

        // Center jewel
        let jewel: CGFloat = r * 0.026
        ctx.fill(Path(ellipseIn: CGRect(x: c.x - jewel, y: c.y - jewel, width: jewel * 2, height: jewel * 2)),
                 with: .color(Color.white))
        let jewelGlow: CGFloat = jewel * 1.8
        var jg = ctx; jg.opacity = 0.4; jg.blendMode = .screen
        jg.fill(Path(ellipseIn: CGRect(x: c.x - jewelGlow, y: c.y - jewelGlow,
                                         width: jewelGlow * 2, height: jewelGlow * 2)),
                with: .radialGradient(Gradient(colors: [Color(red: 1, green: 0.92, blue: 0.55), .clear]),
                                      center: c, startRadius: 0, endRadius: jewelGlow))
    }

    private func drawSunriseHand(ctx: GraphicsContext, center: CGPoint,
                                  angle: Double, length: CGFloat, tail: CGFloat, width: CGFloat) {
        let tip = CGPoint(x: center.x + length * CGFloat(cos(angle)),
                          y: center.y + length * CGFloat(sin(angle)))
        let base = CGPoint(x: center.x - tail * CGFloat(cos(angle)),
                           y: center.y - tail * CGFloat(sin(angle)))
        // Shadow
        var sp = Path()
        sp.move(to: CGPoint(x: base.x + 1, y: base.y + 1))
        sp.addLine(to: CGPoint(x: tip.x + 1, y: tip.y + 1))
        var sc = ctx; sc.opacity = 0.35
        sc.stroke(sp, with: .color(.black), style: StrokeStyle(lineWidth: width, lineCap: .round))
        // Hand
        var p = Path()
        p.move(to: base); p.addLine(to: tip)
        ctx.stroke(p, with: .color(.white), style: StrokeStyle(lineWidth: width, lineCap: .round))
    }

    private func drawSunriseSecond(ctx: GraphicsContext, center: CGPoint, angle: Double, radius: CGFloat) {
        let amber = Color(red: 1.0, green: 0.78, blue: 0.25)
        var p = Path()
        p.move(to: CGPoint(x: center.x - radius * 0.16 * CGFloat(cos(angle)),
                            y: center.y - radius * 0.16 * CGFloat(sin(angle))))
        p.addLine(to: CGPoint(x: center.x + radius * 0.80 * CGFloat(cos(angle)),
                               y: center.y + radius * 0.80 * CGFloat(sin(angle))))
        // Thin shadow
        var sc = ctx; sc.opacity = 0.3
        var sp = Path()
        sp.move(to: CGPoint(x: center.x - radius * 0.16 * CGFloat(cos(angle)) + 0.6,
                             y: center.y - radius * 0.16 * CGFloat(sin(angle)) + 0.6))
        sp.addLine(to: CGPoint(x: center.x + radius * 0.80 * CGFloat(cos(angle)) + 0.6,
                                y: center.y + radius * 0.80 * CGFloat(sin(angle)) + 0.6))
        sc.stroke(sp, with: .color(.black), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
        ctx.stroke(p, with: .color(amber), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
    }
}
