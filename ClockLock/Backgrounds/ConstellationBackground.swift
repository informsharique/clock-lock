import SwiftUI

/// Constellation — A high-performance dynamic plexus of connecting dots.
/// Features a rotating 3D armillary gyroscope structure in the center and floating particles in the background.
/// Nearby nodes are connected with distance-fading blended lines.
/// Driven by TimelineView and Canvas for Metal-accelerated performance.
struct ConstellationBackground: View {
    // Curated color palette
    private static let neonCyan  = ConstellationColor(r: 0.0, g: 0.9, b: 1.0)
    private static let neonPink  = ConstellationColor(r: 1.0, g: 0.2, b: 0.6)
    private static let purple    = ConstellationColor(r: 0.65, g: 0.25, b: 1.0)
    private static let orange    = ConstellationColor(r: 1.0, g: 0.55, b: 0.0)
    private static let neonGreen = ConstellationColor(r: 0.1, g: 0.9, b: 0.4)
    
    // Persistent structures generated once (600 particles for high-DPI/monitor scaling pool)
    @State private var particles: [ConstellationParticle] = ConstellationBackground.generateParticles(count: 600)
    @State private var gyroscopeNodes: [Point3D] = ConstellationBackground.generateGyroscopeNodes()
       var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let minDimension = min(size.width, size.height)
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            
            ZStack {
                // 1. Native SwiftUI Background Gradient (Hardware-dithered, zero banding)
                LinearGradient(
                    colors: [
                        Color(red: 0.02, green: 0.02, blue: 0.05), // Top-left: Very dark blue
                        Color(red: 0.05, green: 0.02, blue: 0.08), // Middle: Very dark indigo/purple
                        Color(red: 0.01, green: 0.01, blue: 0.03)  // Bottom-right: Onyx black
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // 2. Native SwiftUI Central Ambient Glow (Hardware-dithered, zero banding)
                let glowRadius = minDimension * 0.45
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(red: 0.15, green: 0.05, blue: 0.28).opacity(0.32), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: glowRadius
                        )
                    )
                    .frame(width: glowRadius * 2, height: glowRadius * 2)
                    .position(center)
                    .blendMode(.screen)
                
                // 3. Canvas for Plexus & Star drawing (no gradients to cause banding)
                TimelineView(.animation) { timeline in
                    Canvas { ctx, size in
                        let time = timeline.date.timeIntervalSinceReferenceDate
                        
                        // 3. Project 3D Gyroscope Nodes
                        let baseRadius = minDimension * 0.18
                        struct ProjectedNode {
                            let pos: CGPoint
                            let depth: Double // z depth: -1.0 (far) to 1.0 (near)
                            let color: ConstellationColor
                            let ringIndex: Int
                        }
                        
                        var projectedNodes: [ProjectedNode] = []
                        projectedNodes.reserveCapacity(gyroscopeNodes.count)
                        
                        for node in gyroscopeNodes {
                            let rotated = rotate(point: node, time: time)
                            let rScale: Double
                            switch node.ringIndex {
                            case 0: rScale = 1.00
                            case 1: rScale = 0.82
                            default: rScale = 0.64
                            }
                            
                            let xScreen = center.x + rotated.x * baseRadius * rScale
                            let yScreen = center.y + rotated.y * baseRadius * rScale
                            
                            projectedNodes.append(ProjectedNode(
                                pos: CGPoint(x: xScreen, y: yScreen),
                                depth: rotated.z,
                                color: node.color,
                                ringIndex: node.ringIndex
                            ))
                        }
                        
                        // 4. Compute Active Background Particles based on Screen Area (using square root scaling to keep density premium and avoid clutter)
                        let baseArea = 1440.0 * 900.0 // baseline laptop resolution
                        let screenArea = size.width * size.height
                        let scale = max(1.0, sqrt(screenArea / baseArea))
                        let activeCount = min(particles.count, Int(Double(70) * scale)) // baseline 70 particles
                        
                        struct ActiveParticle {
                            let pos: CGPoint
                            let color: ConstellationColor
                            let radius: Double
                        }
                        
                        var activeParticles: [ActiveParticle] = []
                        activeParticles.reserveCapacity(activeCount)
                        
                        for i in 0..<activeCount {
                            let p = particles[i]
                            var x = (p.startX + p.vx * time).truncatingRemainder(dividingBy: 1.0)
                            if x < 0 { x += 1.0 }
                            var y = (p.startY + p.vy * time).truncatingRemainder(dividingBy: 1.0)
                            if y < 0 { y += 1.0 }
                            
                            activeParticles.append(ActiveParticle(
                                pos: CGPoint(x: x * size.width, y: y * size.height),
                                color: p.color,
                                radius: p.radius
                            ))
                        }
                        
                        // 5. Draw Ring Outlines (connect consecutive nodes in each ring)
                        for r in 0..<3 {
                            let offset = r * 16
                            for i in 0..<16 {
                                let nodeA = projectedNodes[offset + i]
                                let nodeB = projectedNodes[offset + ((i + 1) % 16)]
                                
                                let avgDepth = (nodeA.depth + nodeB.depth) / 2.0
                                let opacity = 0.35 + (avgDepth + 1.0) / 2.0 * 0.45 // range 0.35 to 0.80
                                
                                var path = Path()
                                path.move(to: nodeA.pos)
                                path.addLine(to: nodeB.pos)
                                
                                // Solid blended color for drawing lines to avoid NaN shader bugs on short segments
                                let strokeColor = ConstellationColor.blend(nodeA.color, nodeB.color).opacity(opacity)
                                ctx.stroke(path, with: .color(strokeColor), lineWidth: 1.6)
                            }
                        }
                        
                        // 6. Draw Plexus Connections (constant threshold so plexus density and line lengths remain visually identical across screens)
                        let threshold: Double = 140.0
                        struct PlexusNode {
                            let pos: CGPoint
                            let color: ConstellationColor
                            let opacityMultiplier: Double
                            let isGyro: Bool
                            let ringIndex: Int
                        }
                        
                        var plexusNodes: [PlexusNode] = []
                        plexusNodes.reserveCapacity(projectedNodes.count + activeParticles.count)
                        
                        for n in projectedNodes {
                            let opacityMult = 0.35 + (n.depth + 1.0) / 2.0 * 0.65
                            plexusNodes.append(PlexusNode(pos: n.pos, color: n.color, opacityMultiplier: opacityMult, isGyro: true, ringIndex: n.ringIndex))
                        }
                        for p in activeParticles {
                            plexusNodes.append(PlexusNode(pos: p.pos, color: p.color, opacityMultiplier: 0.8, isGyro: false, ringIndex: -1))
                        }
                        
                        let nTotal = plexusNodes.count
                        var connectionCounts = Array(repeating: 0, count: nTotal)
                        
                        for i in 0..<nTotal {
                            let nodeA = plexusNodes[i]
                            for j in (i + 1)..<nTotal {
                                let nodeB = plexusNodes[j]
                                
                                // Skip connections between nodes on the SAME gyroscope ring (already drawn by outline)
                                if nodeA.isGyro && nodeB.isGyro && nodeA.ringIndex == nodeB.ringIndex {
                                    continue
                                }
                                
                                // Connection limits per node type to distribute lines evenly and avoid early loop termination bias
                                let limitA = nodeA.isGyro ? 5 : 4
                                let limitB = nodeB.isGyro ? 5 : 4
                                if connectionCounts[i] >= limitA || connectionCounts[j] >= limitB {
                                    continue
                                }
                                
                                let dx = nodeA.pos.x - nodeB.pos.x
                                let dy = nodeA.pos.y - nodeB.pos.y
                                let distSqr = dx * dx + dy * dy
                                let maxDistSqr = threshold * threshold
                                
                                if distSqr < maxDistSqr {
                                    let dist = sqrt(distSqr)
                                    let factor = 1.0 - (dist / threshold)
                                    let lineOpacity = factor * 0.85 * min(nodeA.opacityMultiplier, nodeB.opacityMultiplier) // bright & visible
                                    
                                    if lineOpacity > 0.02 {
                                        var path = Path()
                                        path.move(to: nodeA.pos)
                                        path.addLine(to: nodeB.pos)
                                        
                                        // Blend colors to avoid GPU NaN shader crashes on short lines
                                        let strokeColor = ConstellationColor.blend(nodeA.color, nodeB.color).opacity(lineOpacity)
                                        ctx.stroke(path, with: .color(strokeColor), lineWidth: 1.2)
                                        
                                        connectionCounts[i] += 1
                                        connectionCounts[j] += 1
                                    }
                                }
                            }
                        }
                        
                        // 7. Draw Dots (Cores + Soft Glowing Halos with Twinkling)
                        // Draw background particles first (underneath gyroscope)
                        for (idx, p) in activeParticles.enumerated() {
                            // Twinkling multiplier: varies over time at unique frequencies & phases per particle
                            let freq = 2.4 + sin(Double(idx) * 0.95) * 1.0
                            let phase = Double(idx) * 1.65
                            let pTwinkle = max(0.25, sin(time * freq + phase) * 0.5 + 0.5) // range 0.25 to 1.0
                            
                            let coreR = p.radius * (0.82 + pTwinkle * 0.18) // core size pulses slightly
                            let haloR = coreR * 3.8
                            
                            let rectHalo = CGRect(x: p.pos.x - haloR, y: p.pos.y - haloR, width: haloR * 2, height: haloR * 2)
                            ctx.fill(
                                Path(ellipseIn: rectHalo),
                                with: .radialGradient(
                                    Gradient(colors: [p.color.opacity(0.28 * pTwinkle), .clear]), // halo opacity pulses
                                    center: p.pos, startRadius: 0, endRadius: haloR
                                )
                            )
                            
                            let rectCore = CGRect(x: p.pos.x - coreR, y: p.pos.y - coreR, width: coreR * 2, height: coreR * 2)
                            ctx.fill(Path(ellipseIn: rectCore), with: .color(p.color.opacity(0.85 * pTwinkle)))
                        }
                        
                        // Draw rotating gyroscope nodes (on top, with depth-based sizes & twinkling)
                        for (idx, n) in projectedNodes.enumerated() {
                            // Twinkling multiplier: varies over time at unique frequencies & phases per node
                            let freq = 3.0 + sin(Double(idx) * 0.8) * 1.3
                            let phase = Double(idx) * 2.1
                            let gTwinkle = max(0.40, sin(time * freq + phase) * 0.45 + 0.55) // range 0.40 to 1.00
                            
                            let depthScale = 0.75 + (n.depth + 1.0) / 2.0 * 0.55 // 0.75x to 1.30x sizing
                            let coreR = 3.8 * depthScale * (0.85 + gTwinkle * 0.15) // core size pulses slightly
                            let haloR = coreR * 3.8
                            let baseOpacity = 0.42 + (n.depth + 1.0) / 2.0 * 0.58 // Foreground nodes are opaque, background nodes fade
                            let opacity = baseOpacity * gTwinkle
                            
                            let rectHalo = CGRect(x: n.pos.x - haloR, y: n.pos.y - haloR, width: haloR * 2, height: haloR * 2)
                            ctx.fill(
                                Path(ellipseIn: rectHalo),
                                with: .radialGradient(
                                    Gradient(colors: [n.color.opacity(opacity * 0.32), .clear]),
                                    center: n.pos, startRadius: 0, endRadius: haloR
                                )
                            )
                            
                            let rectCore = CGRect(x: n.pos.x - coreR, y: n.pos.y - coreR, width: coreR * 2, height: coreR * 2)
                            ctx.fill(Path(ellipseIn: rectCore), with: .color(n.color.opacity(opacity)))
                        }
                    }
                }
                .ignoresSafeArea()
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - 3D Math Helper
    
    private func rotate(point: Point3D, time: Double) -> (x: Double, y: Double, z: Double) {
        let pitch: Double
        let yaw: Double
        let roll: Double
        
        // Dynamic speed ratios per ring for complex, organic interweaving
        switch point.ringIndex {
        case 0:
            pitch = time * 0.08
            yaw = time * 0.12
            roll = time * 0.05
        case 1:
            pitch = time * -0.10
            yaw = time * 0.07
            roll = time * 0.14
        default:
            pitch = time * 0.15
            yaw = time * -0.09
            roll = time * -0.11
        }
        
        // 1. Pitch (X-axis rotation)
        let cosP = cos(pitch)
        let sinP = sin(pitch)
        let y1 = point.y * cosP - point.z * sinP
        let z1 = point.y * sinP + point.z * cosP
        let x1 = point.x
        
        // 2. Yaw (Y-axis rotation)
        let cosY = cos(yaw)
        let sinY = sin(yaw)
        let x2 = x1 * cosY + z1 * sinY
        let z2 = -x1 * sinY + z1 * cosY
        let y2 = y1
        
        // 3. Roll (Z-axis rotation)
        let cosR = cos(roll)
        let sinR = sin(roll)
        let x3 = x2 * cosR - y2 * sinR
        let y3 = x2 * sinR + y2 * cosR
        let z3 = z2
        
        return (x3, y3, z3)
    }
    
    // MARK: - Static Generators
    
    private static func generateGyroscopeNodes() -> [Point3D] {
        var nodes: [Point3D] = []
        
        // Ring index 0 (XY plane outline at start) - Cyan
        for i in 0..<16 {
            let theta = Double(i) * 2.0 * .pi / 16.0
            nodes.append(Point3D(x: cos(theta), y: sin(theta), z: 0.0, ringIndex: 0, color: neonCyan))
        }
        
        // Ring index 1 (YZ plane outline at start) - Pink
        for i in 0..<16 {
            let theta = Double(i) * 2.0 * .pi / 16.0
            nodes.append(Point3D(x: 0.0, y: cos(theta), z: sin(theta), ringIndex: 1, color: neonPink))
        }
        
        // Ring index 2 (XZ plane outline at start) - Orange
        for i in 0..<16 {
            let theta = Double(i) * 2.0 * .pi / 16.0
            nodes.append(Point3D(x: cos(theta), y: 0.0, z: sin(theta), ringIndex: 2, color: orange))
        }
        
        return nodes
    }
    
    private static func generateParticles(count: Int) -> [ConstellationParticle] {
        var particles: [ConstellationParticle] = []
        let colors = [neonCyan, neonPink, purple, orange, neonGreen]
        
        for _ in 0..<count {
            let startX = Double.random(in: 0...1)
            let startY = Double.random(in: 0...1)
            // Velocities relative to screen size per second (very slow movement)
            let vx = Double.random(in: -0.012...0.012)
            let vy = Double.random(in: -0.012...0.012)
            let color = colors.randomElement() ?? neonCyan
            let radius = Double.random(in: 1.5...3.2)
            
            particles.append(ConstellationParticle(
                startX: startX,
                startY: startY,
                vx: vx,
                vy: vy,
                color: color,
                radius: radius
            ))
        }
        return particles
    }
}

// MARK: - Models & Colors helper

struct ConstellationColor {
    let r: Double
    let g: Double
    let b: Double
    
    var color: Color {
        Color(red: r, green: g, blue: b)
    }
    
    func opacity(_ value: Double) -> Color {
        Color(red: r, green: g, blue: b, opacity: value)
    }
    
    static func blend(_ c1: ConstellationColor, _ c2: ConstellationColor) -> Color {
        Color(
            red: (c1.r + c2.r) / 2.0,
            green: (c1.g + c2.g) / 2.0,
            blue: (c1.b + c2.b) / 2.0
        )
    }
}

struct ConstellationParticle {
    let startX: Double
    let startY: Double
    let vx: Double
    let vy: Double
    let color: ConstellationColor
    let radius: Double
}

struct Point3D {
    let x: Double
    let y: Double
    let z: Double
    let ringIndex: Int
    let color: ConstellationColor
}
