import SwiftUI

/// Aurora Borealis — sinusoidal color wave bands that drift slowly across the screen.
/// Performance: Rendered using native SwiftUI Shapes and CAGradientLayer (via LinearGradient)
/// for wide-color hardware dithering with zero banding and zero noise.
struct AuroraBackground: View {
    // Band parameters — 5 bands
    private let bands: [(hue: Double, sat: Double, bri: Double, spd: Double, freq: Double, vOff: Double)] = [
        (0.47, 0.85, 0.60, 1.00, 2.5, 0.10),   // teal-green
        (0.75, 0.80, 0.55, 0.70, 2.0, 0.28),   // violet
        (0.55, 0.75, 0.50, 1.20, 3.0, 0.46),   // cyan
        (0.85, 0.80, 0.50, 0.90, 1.8, 0.64),   // magenta
        (0.35, 0.70, 0.45, 1.10, 2.2, 0.82),   // warm green
    ]

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let phaseScale = 0.24
            
            TimelineView(.animation) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let phase = time * phaseScale
                
                ZStack {
                    // Solid dark base (Core Animation composition)
                    Color(hue: 0.68, saturation: 0.9, brightness: 0.05)
                        .ignoresSafeArea()
                    
                    ForEach(0..<bands.count, id: \.self) { idx in
                        let band = bands[idx]
                        let ph = phase * band.spd + Double(idx) * 1.05
                        let bandH = size.height * 0.22
                        let cY = size.height * band.vOff + sin(ph * 0.25) * size.height * 0.10
                        
                        let color = Color(hue: band.hue, saturation: band.sat, brightness: band.bri)
                        LinearGradient(
                            stops: [
                                .init(color: color.opacity(0.000), location: 0.000),
                                .init(color: color.opacity(0.344), location: 0.125),
                                .init(color: color.opacity(0.636), location: 0.250),
                                .init(color: color.opacity(0.832), location: 0.375),
                                .init(color: color.opacity(0.900), location: 0.500),
                                .init(color: color.opacity(0.832), location: 0.625),
                                .init(color: color.opacity(0.636), location: 0.750),
                                .init(color: color.opacity(0.344), location: 0.875),
                                .init(color: color.opacity(0.000), location: 1.000)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .clipShape(AuroraBandShape(band: band, phase: ph, bandH: bandH, cY: cY, steps: 120))
                            .opacity(0.38)
                            .blendMode(.screen)
                    }
                }
            }
        }
        .ignoresSafeArea()
        .background(Color.black)
    }
}

// Custom Shape representing a sinusoidal wave band
struct AuroraBandShape: Shape {
    let band: (hue: Double, sat: Double, bri: Double, spd: Double, freq: Double, vOff: Double)
    let phase: Double
    let bandH: Double
    let cY: Double
    let steps: Int

    func path(in rect: CGRect) -> Path {
        let dx: Double = rect.width / Double(steps)
        var path = Path()
        
        // Top edge
        path.move(to: CGPoint(x: 0, y: cY - bandH * 0.5 + sin(phase) * bandH * 0.30))
        for i in 1...steps {
            let x = Double(i) * dx
            let y = cY - bandH * 0.5 + sin(x / rect.width * .pi * band.freq + phase) * bandH * 0.30
            path.addLine(to: CGPoint(x: x, y: y))
        }
        // Bottom edge (reversed)
        for i in stride(from: steps, through: 0, by: -1) {
            let x = Double(i) * dx
            let y = cY + bandH * 0.5 + sin(x / rect.width * .pi * band.freq + phase + 1.0) * bandH * 0.30
            path.addLine(to: CGPoint(x: x, y: y))
        }
        path.closeSubpath()
        return path
    }
}
