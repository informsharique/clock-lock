import SwiftUI
import AppKit

/// Ember — fire embers rising from the bottom.
/// Driven entirely by Core Animation (CAEmitterLayer) on the system render server.
/// Zero CPU simulation overhead, 100% fluid GPU-rendered motion.
struct EmberBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> EmberNSView {
        EmberNSView()
    }
    
    func updateNSView(_ nsView: EmberNSView, context: Context) {
        // Self-contained on the GPU, no updates required
    }
}

class EmberNSView: NSView {
    private let emitterLayer = CAEmitterLayer()
    private let backgroundLayer = CAGradientLayer()
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupLayer()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayer()
    }
    
    private func setupLayer() {
        wantsLayer = true
        
        // Single unified vertical gradient spanning the entire screen (100% seamless, no overlap)
        backgroundLayer.colors = [
            NSColor(red: 0.02, green: 0.01, blue: 0.01, alpha: 1.0).cgColor, // Top: Pure dark onyx
            NSColor(red: 0.05, green: 0.01, blue: 0.01, alpha: 1.0).cgColor, // Middle: Subtle dark red-black
            NSColor(red: 0.12, green: 0.02, blue: 0.0, alpha: 1.0).cgColor   // Bottom: Warm crimson-black glow
        ]
        backgroundLayer.locations = [0.0, 0.45, 1.0]
        backgroundLayer.startPoint = CGPoint(x: 0.5, y: 1.0) // Top
        backgroundLayer.endPoint = CGPoint(x: 0.5, y: 0.0)   // Bottom
        layer?.addSublayer(backgroundLayer)
        
        // Setup emitter
        emitterLayer.emitterPosition = CGPoint(x: bounds.midX, y: -20)
        emitterLayer.emitterSize = CGSize(width: bounds.width, height: 10)
        emitterLayer.emitterShape = .line
        emitterLayer.renderMode = .additive
        
        // Emitters require a CGImage cell content.
        let image = makeParticleImage()
        
        // Large bright embers
        let cell = CAEmitterCell()
        cell.birthRate = 20
        cell.lifetime = 9.0
        cell.lifetimeRange = 2.5
        cell.velocity = 130
        cell.velocityRange = 30
        cell.emissionLongitude = .pi // Straight UP in this coordinate configuration
        cell.emissionRange = 0.16
        cell.xAcceleration = 0
        cell.yAcceleration = 16 // float up (positive Y acceleration in Y-up space)
        cell.scale = 0.22
        cell.scaleRange = 0.12
        cell.scaleSpeed = -0.012
        cell.alphaSpeed = -0.10 // fades out slowly as it reaches the top
        cell.contents = image
        
        // Tiny fast embers (sparks)
        let sparkCell = CAEmitterCell()
        sparkCell.birthRate = 28
        sparkCell.lifetime = 7.0
        sparkCell.lifetimeRange = 2.0
        sparkCell.velocity = 170
        sparkCell.velocityRange = 40
        sparkCell.emissionLongitude = .pi // Straight UP
        sparkCell.emissionRange = 0.24
        sparkCell.xAcceleration = 0
        sparkCell.yAcceleration = 26 // float up
        sparkCell.scale = 0.10
        sparkCell.scaleRange = 0.05
        sparkCell.scaleSpeed = -0.008
        sparkCell.alphaSpeed = -0.13
        sparkCell.contents = image
        
        emitterLayer.emitterCells = [cell, sparkCell]
        layer?.addSublayer(emitterLayer)
    }
    
    override func layout() {
        super.layout()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        backgroundLayer.frame = bounds
        emitterLayer.frame = bounds
        emitterLayer.emitterPosition = CGPoint(x: bounds.width / 2, y: -20)
        emitterLayer.emitterSize = CGSize(width: bounds.width, height: 10)
        
        CATransaction.commit()
    }
    
    private func makeParticleImage() -> CGImage? {
        let size = CGSize(width: 32, height: 32)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: nil,
                                      width: Int(size.width),
                                      height: Int(size.height),
                                      bitsPerComponent: 8,
                                      bytesPerRow: 0,
                                      space: colorSpace,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return nil
        }
        
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = size.width / 2
        
        let colors = [
            CGColor(red: 1.0, green: 0.7, blue: 0.3, alpha: 1.0),
            CGColor(red: 1.0, green: 0.3, blue: 0.0, alpha: 0.7),
            CGColor(red: 0.8, green: 0.08, blue: 0.0, alpha: 0.0)
        ] as CFArray
        
        let locations: [CGFloat] = [0.0, 0.45, 1.0]
        guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) else {
            return nil
        }
        
        context.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: radius, options: [])
        return context.makeImage()
    }
}
