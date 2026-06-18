import SwiftUI
import Foundation

/// "Neon" — Pure black dial with electric neon-glowing hands.
/// Hour hand: electric cyan. Minute hand: ice blue-white. Seconds: hot pink.
/// Glow is simulated with multi-layer screen-blend strokes.
struct ClockNeon: View {
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

    // Hour dot hues — cycling spectrum
    private static let hourHues: [Double] = (0..<12).map { Double($0) / 12.0 }

    var body: some View {
        GeometryReader { geo in
            let size: CGFloat = min(geo.size.width, geo.size.height)
            neonDial(size: size)
        }
    }

    @ViewBuilder
    private func neonDial(size: CGFloat) -> some View {
        ZStack {
            // Pure black base
            Circle()
                .fill(Color.black)

            // Outer bezel — thin electric blue-purple glow ring
            Circle()
                .strokeBorder(
                    AngularGradient(
                        colors: [
                            Color(hue: 0.58, saturation: 1, brightness: 0.9),
                            Color(hue: 0.78, saturation: 1, brightness: 0.7),
                            Color(hue: 0.92, saturation: 1, brightness: 0.8),
                            Color(hue: 0.58, saturation: 1, brightness: 0.9),
                        ],
                        center: .center
                    ),
                    lineWidth: size * 0.008
                )

            Canvas { ctx, cSize in
                renderNeon(ctx: ctx, size: cSize)
            }
        }
    }

    private func renderNeon(ctx: GraphicsContext, size: CGSize) {
        let c = CGPoint(x: round(size.width / 2), y: round(size.height / 2))
        let r: CGFloat = min(size.width, size.height) / 2
        let ang = angles

        // Hour marker dots with glow
        drawHourDots(ctx: ctx, center: c, radius: r)

        // Minute tick marks (subtle, white dim)
        for i in 0..<60 {
            if i % 5 == 0 { continue }
            let a: Double = Double(i) / 60.0 * 2 * .pi - .pi / 2
            let outerR: CGFloat = r * 0.88
            var tick = Path()
            tick.move(to: CGPoint(x: c.x + outerR * CGFloat(cos(a)), y: c.y + outerR * CGFloat(sin(a))))
            tick.addLine(to: CGPoint(x: c.x + (outerR - r * 0.028) * CGFloat(cos(a)),
                                      y: c.y + (outerR - r * 0.028) * CGFloat(sin(a))))
            ctx.stroke(tick, with: .color(Color.white.opacity(0.18)), lineWidth: 0.8)
        }

        // Hour hand — electric cyan
        let cyan = Color(hue: 0.51, saturation: 1.0, brightness: 1.0)
        drawNeonHand(ctx: ctx, center: c,
                     angle: ang.h, length: r * 0.48, tailLen: r * 0.12,
                     coreWidth: r * 0.022, coreColor: Color.white, glowColor: cyan)

        // Minute hand — ice blue
        let iceBlue = Color(hue: 0.58, saturation: 0.7, brightness: 1.0)
        drawNeonHand(ctx: ctx, center: c,
                     angle: ang.m, length: r * 0.72, tailLen: r * 0.14,
                     coreWidth: r * 0.014, coreColor: Color.white, glowColor: iceBlue)

        // Seconds — hot pink/magenta with comet trail
        drawNeonSeconds(ctx: ctx, center: c, angle: ang.s, radius: r)

        // Center orb
        drawCenterOrb(ctx: ctx, center: c, radius: r)
    }

    private func drawHourDots(ctx: GraphicsContext, center: CGPoint, radius: CGFloat) {
        let dotR: CGFloat = radius * 0.89
        for i in 0..<12 {
            let a: Double = Double(i) / 12.0 * 2 * .pi - .pi / 2
            let hue = Self.hourHues[i]
            let color = Color(hue: hue, saturation: 1.0, brightness: 1.0)
            let cx: CGFloat = center.x + dotR * CGFloat(cos(a))
            let cy: CGFloat = center.y + dotR * CGFloat(sin(a))
            let ds: CGFloat = i % 3 == 0 ? radius * 0.022 : radius * 0.014

            // Glow
            let gRect = CGRect(x: cx - ds * 2.5, y: cy - ds * 2.5, width: ds * 5, height: ds * 5)
            var gc = ctx
            gc.opacity = 0.4
            gc.blendMode = .screen
            gc.fill(Path(ellipseIn: gRect),
                    with: .radialGradient(Gradient(colors: [color, .clear]),
                                          center: CGPoint(x: cx, y: cy), startRadius: 0, endRadius: ds * 2.5))

            // Solid dot
            let dRect = CGRect(x: cx - ds, y: cy - ds, width: ds * 2, height: ds * 2)
            ctx.fill(Path(ellipseIn: dRect), with: .color(color))
        }
    }

    private func drawNeonHand(ctx: GraphicsContext, center: CGPoint,
                               angle: Double, length: CGFloat, tailLen: CGFloat,
                               coreWidth: CGFloat, coreColor: Color, glowColor: Color) {
        let tip = CGPoint(x: center.x + length * CGFloat(cos(angle)),
                          y: center.y + length * CGFloat(sin(angle)))
        let tail = CGPoint(x: center.x - tailLen * CGFloat(cos(angle)),
                           y: center.y - tailLen * CGFloat(sin(angle)))
        var p = Path()
        p.move(to: tail)
        p.addLine(to: tip)

        // Outer bloom
        var gc1 = ctx
        gc1.opacity = 0.12; gc1.blendMode = .screen
        gc1.stroke(p, with: .color(glowColor), style: StrokeStyle(lineWidth: coreWidth * 7, lineCap: .round))
        // Mid glow
        var gc2 = ctx
        gc2.opacity = 0.22; gc2.blendMode = .screen
        gc2.stroke(p, with: .color(glowColor), style: StrokeStyle(lineWidth: coreWidth * 3.5, lineCap: .round))
        // Inner glow
        var gc3 = ctx
        gc3.opacity = 0.45; gc3.blendMode = .screen
        gc3.stroke(p, with: .color(glowColor), style: StrokeStyle(lineWidth: coreWidth * 1.8, lineCap: .round))
        // Core
        ctx.stroke(p, with: .color(coreColor), style: StrokeStyle(lineWidth: coreWidth, lineCap: .round))
    }

    private func drawNeonSeconds(ctx: GraphicsContext, center: CGPoint, angle: Double, radius: CGFloat) {
        let pink = Color(hue: 0.92, saturation: 1.0, brightness: 1.0)
        let tip = CGPoint(x: center.x + radius * 0.80 * CGFloat(cos(angle)),
                          y: center.y + radius * 0.80 * CGFloat(sin(angle)))
        let tail = CGPoint(x: center.x - radius * 0.20 * CGFloat(cos(angle)),
                           y: center.y - radius * 0.20 * CGFloat(sin(angle)))
        var p = Path()
        p.move(to: tail)
        p.addLine(to: tip)

        // Bloom layers
        var gc1 = ctx; gc1.opacity = 0.10; gc1.blendMode = .screen
        gc1.stroke(p, with: .color(pink), style: StrokeStyle(lineWidth: 14, lineCap: .round))
        var gc2 = ctx; gc2.opacity = 0.25; gc2.blendMode = .screen
        gc2.stroke(p, with: .color(pink), style: StrokeStyle(lineWidth: 5, lineCap: .round))
        var gc3 = ctx; gc3.opacity = 0.6; gc3.blendMode = .screen
        gc3.stroke(p, with: .color(pink), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
        ctx.stroke(p, with: .color(.white), style: StrokeStyle(lineWidth: 1.0, lineCap: .round))

        // Tip dot
        let tipDot: CGFloat = radius * 0.018
        ctx.fill(Path(ellipseIn: CGRect(x: tip.x - tipDot, y: tip.y - tipDot,
                                         width: tipDot * 2, height: tipDot * 2)),
                 with: .color(.white))
    }

    private func drawCenterOrb(ctx: GraphicsContext, center: CGPoint, radius: CGFloat) {
        let cyan = Color(hue: 0.51, saturation: 1.0, brightness: 1.0)
        let orbR: CGFloat = radius * 0.030
        // Glow
        var gc = ctx; gc.opacity = 0.5; gc.blendMode = .screen
        gc.fill(Path(ellipseIn: CGRect(x: center.x - orbR * 3, y: center.y - orbR * 3,
                                        width: orbR * 6, height: orbR * 6)),
                with: .radialGradient(Gradient(colors: [cyan, .clear]),
                                      center: center, startRadius: 0, endRadius: orbR * 3))
        // Core
        ctx.fill(Path(ellipseIn: CGRect(x: center.x - orbR, y: center.y - orbR,
                                         width: orbR * 2, height: orbR * 2)),
                 with: .color(.white))
    }
}
