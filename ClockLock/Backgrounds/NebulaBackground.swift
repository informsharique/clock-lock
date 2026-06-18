import SwiftUI

/// Nebula — deep space with slowly drifting color clouds and a glittering star field.
/// Performance: Clouds are rendered using native SwiftUI Ellipse views and RadialGradient
/// for wide-color hardware dithering with zero banding and zero noise.
/// The star field is rendered inside a lightweight Canvas on top.
struct NebulaBackground: View {
    // Static: computed once for the lifetime of the app, never regenerated
    private static let stars: [(x: Double, y: Double, size: Double, brightness: Double)] = {
        (0..<120).map { _ in
            (
                Double.random(in: 0...1),
                Double.random(in: 0...1),
                Double.random(in: 1.2...3.0),
                Double.random(in: 0.3...1.0)
            )
        }
    }()

    // Nebula cloud layers (slowly drifting radial gradients)
    private let clouds: [(cx: Double, cy: Double, rx: Double, ry: Double, hue: Double, sat: Double, bri: Double)] = [
        (0.25, 0.40, 0.45, 0.35, 0.72, 0.7, 0.5),
        (0.65, 0.50, 0.40, 0.30, 0.60, 0.8, 0.45),
        (0.45, 0.65, 0.50, 0.25, 0.08, 0.7, 0.40),
        (0.75, 0.25, 0.35, 0.28, 0.78, 0.6, 0.38),
        (0.15, 0.70, 0.30, 0.22, 0.55, 0.75, 0.35),
    ]

    private func cloudGradient(hue: Double, sat: Double, bri: Double, maxR: CGFloat) -> RadialGradient {
        let steps = 9
        var stops: [Gradient.Stop] = []
        for i in 0..<steps {
            let t = Double(i) / Double(steps - 1)
            let opacityFactor = cos(t * .pi / 2.0)
            
            let s = sat * (1.0 - t * 0.5)
            let b = bri * (1.0 - t * 0.5)
            
            stops.append(.init(
                color: Color(hue: hue, saturation: s, brightness: b).opacity(opacityFactor),
                location: t
            ))
        }
        return RadialGradient(stops: stops, center: .center, startRadius: 0, endRadius: maxR)
    }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let driftScale = 0.48
            let twinkleScale = 1.5
            
            TimelineView(.animation) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let drift = time * driftScale
                let twinkle = time * twinkleScale
                
                ZStack {
                    // Deep space base
                    Color(red: 0.01, green: 0.01, blue: 0.06)
                        .ignoresSafeArea()
                    
                    // Native SwiftUI Clouds (Core Animation hardware-dithered gradients)
                    ForEach(0..<clouds.count, id: \.self) { idx in
                        let cloud = clouds[idx]
                        let driftX = sin(drift * 0.4 + Double(idx) * 1.2) * 0.03
                        let driftY = cos(drift * 0.3 + Double(idx) * 0.8) * 0.025
                        let cx = (cloud.cx + driftX) * size.width
                        let cy = (cloud.cy + driftY) * size.height
                        let rx = cloud.rx * size.width
                        let ry = cloud.ry * size.height
                        
                        cloudGradient(hue: cloud.hue, sat: cloud.sat, bri: cloud.bri, maxR: max(rx, ry))
                            .clipShape(Ellipse())
                            .frame(width: rx * 2, height: ry * 2)
                            .position(x: cx, y: cy)
                            .opacity(0.28)
                            .blendMode(.screen)
                    }
                    
                    // Star field Canvas (only draws solid color circles, zero banding issues)
                    Canvas { context, size in
                        for star in Self.stars {
                            let brightness = 0.6 + 0.4 * sin(twinkle + star.x * 31.4 + star.y * 17.3)
                            let opacity = star.brightness * brightness
                            let cx = star.x * size.width
                            let cy = star.y * size.height
                            let r = star.size / 2
                            
                            context.fill(
                                Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: star.size, height: star.size)),
                                with: .color(Color.white.opacity(opacity))
                            )
                        }
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}
