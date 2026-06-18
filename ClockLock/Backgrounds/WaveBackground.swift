import SwiftUI

/// Wave — overlapping sine wave bands with shifting hue.
/// Performance: Rendered using native SwiftUI Shapes and CAGradientLayer (via LinearGradient)
/// for wide-color hardware dithering with zero banding and zero noise.
struct WaveBackground: View {
    // Premium parameters: 6 layers, higher step count, screen blend mode
    private let layerParams: [(amp: Double, freq: Double, spd: Double, base: Double, hueShift: Double, alpha: Double, thick: Double)] = [
        (0.08, 2.2, 0.80, 0.25, 0.00, 0.65, 0.16),
        (0.10, 1.7, 0.55, 0.40, 0.10, 0.60, 0.18),
        (0.07, 2.8, 1.10, 0.55, 0.20, 0.55, 0.15),
        (0.12, 1.4, 0.45, 0.68, 0.30, 0.50, 0.20),
        (0.09, 2.5, 0.95, 0.80, 0.40, 0.45, 0.14),
        (0.11, 1.9, 0.65, 0.88, 0.50, 0.40, 0.17),
    ]
    
    private func waveGradient(hue: Double, alpha: Double) -> LinearGradient {
        let steps = 9
        var stops: [Gradient.Stop] = []
        for i in 0..<steps {
            let t = Double(i) / Double(steps - 1)
            let tSmooth = (1.0 - cos(t * .pi)) / 2.0 // Cosine ease-in-out curve
            
            let h = hue + (0.05 * tSmooth)
            let s = 0.85 + (0.05 * tSmooth)
            let b = 0.90 - (0.20 * tSmooth)
            let o = alpha * (0.70 - 0.55 * tSmooth)
            
            stops.append(.init(
                color: Color(hue: h.truncatingRemainder(dividingBy: 1.0), saturation: s, brightness: b).opacity(o),
                location: t
            ))
        }
        return LinearGradient(stops: stops, startPoint: .top, endPoint: .bottom)
    }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            
            TimelineView(.animation) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate
                
                // Slow shifting hue base
                let hueOffset = (time * 0.003).truncatingRemainder(dividingBy: 1.0)
                let baseHue = (hueOffset + 0.62).truncatingRemainder(dividingBy: 1.0)
                
                ZStack {
                    // Base background fill (dark shifting color, dithered)
                    Color(hue: baseHue, saturation: 0.95, brightness: 0.08)
                        .ignoresSafeArea()
                    
                    ForEach(0..<layerParams.count, id: \.self) { idx in
                        let lp = layerParams[idx]
                        let hue = (hueOffset + lp.hueShift).truncatingRemainder(dividingBy: 1.0)
                        let phase = time * 0.9 * lp.spd
                        let baseY = lp.base * size.height
                        let amp = lp.amp * size.height
                        let thick = lp.thick * size.height
                        
                        waveGradient(hue: hue, alpha: lp.alpha)
                            .clipShape(WaveShape(phase: phase, baseY: baseY, amp: amp, thick: thick, freq: lp.freq, steps: 120))
                            .frame(height: baseY + thick + amp)
                            .position(x: size.width / 2, y: (baseY + thick + amp) / 2)
                            .blendMode(.screen)
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}

// Custom Shape representing a sine wave layer
struct WaveShape: Shape {
    let phase: Double
    let baseY: Double
    let amp: Double
    let thick: Double
    let freq: Double
    let steps: Int

    func path(in rect: CGRect) -> Path {
        let dx: Double = rect.width / Double(steps)
        var path = Path()
        
        path.move(to: CGPoint(x: 0, y: baseY + sin(phase) * amp))
        for i in 1...steps {
            let x = Double(i) * dx
            let y = baseY + sin(x / rect.width * .pi * freq * 2 + phase) * amp
            path.addLine(to: CGPoint(x: x, y: y))
        }
        path.addLine(to: CGPoint(x: rect.width, y: baseY + thick + amp))
        path.addLine(to: CGPoint(x: 0, y: baseY + thick + amp))
        path.closeSubpath()
        return path
    }
}
