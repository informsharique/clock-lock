import SwiftUI
import Foundation

/// "Crystal" — A gemstone-cut clock.
/// Two iridescent jewel rings drawn as arc segments directly in Canvas (no SwiftUI
/// ring layers, no blend modes, no separate timer). Shimmer derived from the passed
/// date so no extra 60fps timer fires in the preferences thumbnail.
struct ClockCrystal: View {
    let date: Date

    // All hand angles including nanosecond precision
    private var angles: (h: Double, m: Double, s: Double) {
        let cal = Calendar.current
        let h  = Double(cal.component(.hour,       from: date)).truncatingRemainder(dividingBy: 12)
        let m  = Double(cal.component(.minute,     from: date))
        let s  = Double(cal.component(.second,     from: date))
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

    /// Hue rotation derived from time — no separate timer needed.
    /// Cycles through one full hue revolution every 30 seconds.
    private var shimmerOffset: Double {
        date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 30.0) / 30.0
    }

    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                renderCrystal(ctx: ctx, size: size)
            }
        }
    }

    // MARK: - Main render (everything in one Canvas pass)

    private func renderCrystal(ctx: GraphicsContext, size: CGSize) {
        let c = CGPoint(x: round(size.width / 2), y: round(size.height / 2))
        let r: CGFloat = min(size.width, size.height) / 2
        let ang = angles

        // Dark base
        ctx.fill(
            Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)),
            with: .color(Color(red: 0.02, green: 0.01, blue: 0.08))
        )

        // ── Crystal jewel rings ─────────────────────────────────────
        // Two concentric iridescent rings drawn as 60 arc segments each.
        // No SwiftUI view layers, no blend modes — very fast.
        let hueBase = shimmerOffset  // slowly shifts
        drawJewelRing(ctx: ctx, c: c, innerR: r * 0.32, outerR: r * 0.47,
                      hueBase: hueBase, hueReverse: false)
        drawJewelRing(ctx: ctx, c: c, innerR: r * 0.49, outerR: r * 0.60,
                      hueBase: hueBase + 0.5, hueReverse: true)

        // ── Outer tick ring ─────────────────────────────────────────
        for i in 0..<60 {
            let a: Double = Double(i) / 60.0 * 2 * .pi - .pi / 2
            let isQuarter = i % 15 == 0
            let isHour    = i % 5  == 0
            let outerR: CGFloat = r * 0.88
            let len: CGFloat = isQuarter ? r * 0.09 : isHour ? r * 0.06 : r * 0.03
            let w: CGFloat   = isQuarter ? 2.0 : isHour ? 1.2 : 0.7

            var tick = Path()
            tick.move(to: CGPoint(x: c.x + outerR * CGFloat(cos(a)),
                                   y: c.y + outerR * CGFloat(sin(a))))
            tick.addLine(to: CGPoint(x: c.x + (outerR - len) * CGFloat(cos(a)),
                                      y: c.y + (outerR - len) * CGFloat(sin(a))))
            ctx.stroke(tick, with: .color(Color.white.opacity(isHour ? 0.70 : 0.28)), lineWidth: w)
        }

        // ── Hour markers — colored dots at 72% radius ───────────────
        let mkR: CGFloat = r * 0.72
        for i in 0..<12 {
            let a: Double  = Double(i) / 12.0 * 2 * .pi - .pi / 2
            let hue: Double = Double(i) / 12.0
            let mk = CGPoint(x: c.x + mkR * CGFloat(cos(a)), y: c.y + mkR * CGFloat(sin(a)))
            let ds: CGFloat = i % 3 == 0 ? r * 0.022 : r * 0.014
            ctx.fill(
                Path(ellipseIn: CGRect(x: mk.x - ds, y: mk.y - ds, width: ds * 2, height: ds * 2)),
                with: .color(Color(hue: hue, saturation: 0.9, brightness: 1.0).opacity(0.9))
            )
        }

        // ── Hands ───────────────────────────────────────────────────
        drawHand(ctx: ctx, c: c, angle: ang.h, len: r * 0.48, tail: r * 0.12, w: r * 0.020)
        drawHand(ctx: ctx, c: c, angle: ang.m, len: r * 0.72, tail: r * 0.14, w: r * 0.013)
        drawSecond(ctx: ctx, c: c, angle: ang.s, r: r)

        // ── Center gem ──────────────────────────────────────────────
        let gemR: CGFloat = r * 0.040
        ctx.fill(
            Path(ellipseIn: CGRect(x: c.x - gemR, y: c.y - gemR, width: gemR * 2, height: gemR * 2)),
            with: .radialGradient(
                Gradient(stops: [
                    .init(color: .white,                                               location: 0.0),
                    .init(color: Color(hue: 0.62, saturation: 0.8, brightness: 1.0),  location: 0.5),
                    .init(color: Color(hue: 0.75, saturation: 0.9, brightness: 0.7),  location: 1.0),
                ]),
                center: c, startRadius: 0, endRadius: gemR
            )
        )
    }

    // MARK: - Jewel ring

    /// Draws one iridescent ring as 60 solid-color annular arc segments.
    private func drawJewelRing(ctx: GraphicsContext, c: CGPoint,
                                innerR: CGFloat, outerR: CGFloat,
                                hueBase: Double, hueReverse: Bool) {
        let segCount = 60
        for i in 0..<segCount {
            let t = Double(i) / Double(segCount)
            let startA: Double = t * 2 * .pi - .pi / 2
            let endA:   Double = (t + 1.0 / Double(segCount)) * 2 * .pi - .pi / 2

            let hueT = hueReverse ? 1.0 - t : t
            let hue = (hueBase + hueT).truncatingRemainder(dividingBy: 1.0)
            let color = Color(hue: hue, saturation: 0.95, brightness: 1.0).opacity(0.80)

            ctx.fill(
                annularSector(c: c, innerR: innerR, outerR: outerR, startA: startA, endA: endA),
                with: .color(color)
            )
        }
    }

    /// Returns a Path that is one segment of an annular (donut) ring.
    private func annularSector(c: CGPoint, innerR: CGFloat, outerR: CGFloat,
                                 startA: Double, endA: Double) -> Path {
        var p = Path()
        // Outer arc CCW
        p.addArc(center: c, radius: outerR,
                 startAngle: .radians(startA), endAngle: .radians(endA), clockwise: false)
        // Line to inner arc
        p.addLine(to: CGPoint(x: c.x + innerR * CGFloat(cos(endA)),
                               y: c.y + innerR * CGFloat(sin(endA))))
        // Inner arc CW (back to start)
        p.addArc(center: c, radius: innerR,
                 startAngle: .radians(endA), endAngle: .radians(startA), clockwise: true)
        p.closeSubpath()
        return p
    }

    // MARK: - Hand drawing

    private func drawHand(ctx: GraphicsContext, c: CGPoint,
                           angle: Double, len: CGFloat, tail: CGFloat, w: CGFloat) {
        var p = Path()
        p.move(to:    CGPoint(x: c.x - tail * CGFloat(cos(angle)), y: c.y - tail * CGFloat(sin(angle))))
        p.addLine(to: CGPoint(x: c.x + len  * CGFloat(cos(angle)), y: c.y + len  * CGFloat(sin(angle))))
        ctx.stroke(p, with: .color(.white), style: StrokeStyle(lineWidth: w, lineCap: .round))
    }

    private func drawSecond(ctx: GraphicsContext, c: CGPoint, angle: Double, r: CGFloat) {
        let frac = (angle + .pi / 2) / (2 * .pi)
        let color = Color(hue: frac.truncatingRemainder(dividingBy: 1), saturation: 0.9, brightness: 1.0)
        var p = Path()
        p.move(to:    CGPoint(x: c.x - r * 0.16 * CGFloat(cos(angle)), y: c.y - r * 0.16 * CGFloat(sin(angle))))
        p.addLine(to: CGPoint(x: c.x + r * 0.78 * CGFloat(cos(angle)), y: c.y + r * 0.78 * CGFloat(sin(angle))))
        ctx.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
    }
}
