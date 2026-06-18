import SwiftUI
import Foundation

/// "Spectrum" — Jet-black circular dial with a full rainbow AngularGradient ring.
/// The second hand color matches its spectral position. White minimal hands.
struct ClockSpectrum: View {
    let date: Date

    // 13 stops so the gradient completes a full, smooth hue cycle
    private static let ringColors: [Color] = (0...12).map { i in
        Color(hue: Double(i) / 12.0, saturation: 0.95, brightness: 1.0)
    }

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
            spectrumDial(size: size)
        }
    }

    @ViewBuilder
    private func spectrumDial(size: CGFloat) -> some View {
        ZStack {
            // Deep space black dial
            Circle()
                .fill(Color(red: 0.04, green: 0.04, blue: 0.08))

            // Outer bezel — subtle metallic ring
            Circle()
                .strokeBorder(
                    AngularGradient(
                        colors: [Color(white: 0.35), Color(white: 0.18), Color(white: 0.35), Color(white: 0.18), Color(white: 0.35)],
                        center: .center
                    ),
                    lineWidth: size * 0.012
                )

            // Spectrum rainbow ring — the hero element
            Circle()
                .strokeBorder(
                    AngularGradient(
                        colors: Self.ringColors,
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    lineWidth: size * 0.058
                )
                .padding(size * 0.060)

            // Inner separation ring
            Circle()
                .strokeBorder(Color(white: 0.12), lineWidth: 0.5)
                .padding(size * 0.112)

            // Canvas: ticks + hands
            Canvas { ctx, cSize in
                renderSpectrum(ctx: ctx, size: cSize)
            }
        }
    }

    private func renderSpectrum(ctx: GraphicsContext, size: CGSize) {
        let c = CGPoint(x: round(size.width / 2), y: round(size.height / 2))
        let r: CGFloat = min(size.width, size.height) / 2
        let ang = angles

        // Tick marks — drawn inside the ring
        for i in 0..<60 {
            let a: Double = Double(i) / 60.0 * 2 * .pi - .pi / 2
            let isQuarter = i % 15 == 0
            let isHour = i % 5 == 0
            let outerR: CGFloat = r * 0.86
            let len: CGFloat = isQuarter ? r * 0.095 : isHour ? r * 0.065 : r * 0.032
            let w: CGFloat = isQuarter ? 2.2 : isHour ? 1.4 : 0.8
            let opacity: Double = isHour ? 0.9 : 0.45

            var tick = Path()
            tick.move(to: CGPoint(x: c.x + outerR * CGFloat(cos(a)), y: c.y + outerR * CGFloat(sin(a))))
            tick.addLine(to: CGPoint(x: c.x + (outerR - len) * CGFloat(cos(a)), y: c.y + (outerR - len) * CGFloat(sin(a))))
            ctx.stroke(tick, with: .color(Color.white.opacity(opacity)), lineWidth: w)
        }

        // Hour hand — thick white baton
        drawFilledHand(ctx: ctx, center: c,
                       angle: ang.h, length: r * 0.48, tailLen: r * 0.12,
                       width: r * 0.034, color: .white)

        // Minute hand — thin white
        drawFilledHand(ctx: ctx, center: c,
                       angle: ang.m, length: r * 0.72, tailLen: r * 0.14,
                       width: r * 0.020, color: .white)

        // Seconds hand — colored to match its angular position in the spectrum
        let secFraction = (ang.s + .pi / 2) / (2 * .pi)
        let secColor = Color(hue: secFraction.truncatingRemainder(dividingBy: 1),
                             saturation: 0.95, brightness: 1.0)
        drawSecondHand(ctx: ctx, center: c, angle: ang.s, radius: r, color: secColor)

        // Center pip
        let pip: CGFloat = r * 0.028
        ctx.fill(Path(ellipseIn: CGRect(x: c.x - pip, y: c.y - pip, width: pip * 2, height: pip * 2)),
                 with: .color(.white))
    }

    private func drawFilledHand(ctx: GraphicsContext, center: CGPoint,
                                 angle: Double, length: CGFloat, tailLen: CGFloat,
                                 width: CGFloat, color: Color) {
        var p = Path()
        p.move(to: CGPoint(x: center.x - tailLen * CGFloat(cos(angle)),
                            y: center.y - tailLen * CGFloat(sin(angle))))
        p.addLine(to: CGPoint(x: center.x + length * CGFloat(cos(angle)),
                               y: center.y + length * CGFloat(sin(angle))))
        ctx.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round))
    }

    private func drawSecondHand(ctx: GraphicsContext, center: CGPoint,
                                 angle: Double, radius: CGFloat, color: Color) {
        var p = Path()
        p.move(to: CGPoint(x: center.x - radius * 0.18 * CGFloat(cos(angle)),
                            y: center.y - radius * 0.18 * CGFloat(sin(angle))))
        p.addLine(to: CGPoint(x: center.x + radius * 0.78 * CGFloat(cos(angle)),
                               y: center.y + radius * 0.78 * CGFloat(sin(angle))))

        // Soft glow layer
        var gc = ctx
        gc.opacity = 0.35
        gc.blendMode = .screen
        gc.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: 5.0, lineCap: .round))

        // Crisp core
        ctx.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
    }
}
