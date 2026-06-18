import SwiftUI

// MARK: - Style Enums

enum ClockStyle: String, CaseIterable, Identifiable {
    case spectrum = "spectrum"  // Rainbow gradient ring
    case neon     = "neon"      // Neon glow on black
    case sunrise  = "sunrise"   // Warm radial gradient
    case void     = "void"      // Squircle dark blue
    case crystal  = "crystal"   // Iridescent ring stack

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .spectrum: return "Spectrum"
        case .neon:     return "Neon"
        case .sunrise:  return "Sunrise"
        case .void:     return "Void"
        case .crystal:  return "Crystal"
        }
    }
}

enum BackgroundStyle: String, CaseIterable, Identifiable {
    case aurora    = "aurora"
    case nebula    = "nebula"
    case wave      = "wave"
    case geometric = "geometric"
    case ember     = "ember"
    case constellation = "constellation"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .aurora:    return "Aurora"
        case .nebula:    return "Nebula"
        case .wave:      return "Wave"
        case .geometric: return "Geometric"
        case .ember:     return "Ember"
        case .constellation: return "Constellation"
        }
    }
}

// MARK: - Root Host View

/// Layers the selected animated background behind the selected clock face.
/// Reads selections from ClockSettings via environmentObject so no view
/// recreation is needed when preferences change — just a SwiftUI re-render.
struct ClockHostView: View {
    @EnvironmentObject var settings: ClockSettings

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let clockDiameter = min(size.width, size.height) * 0.52
            
            ZStack {
                backgroundView
                    .ignoresSafeArea()
                
                TimelineView(.animation) { timeline in
                    clockView(for: settings.clockStyle, date: timeline.date)
                        .frame(width: clockDiameter, height: clockDiameter)
                }
            }
            .frame(width: size.width, height: size.height)
        }
    }

    // MARK: - Background

    @ViewBuilder
    private var backgroundView: some View {
        switch settings.backgroundStyle {
        case .aurora:    AuroraBackground()
        case .nebula:    NebulaBackground()
        case .wave:      WaveBackground()
        case .geometric: GeomBackground()
        case .ember:     EmberBackground()
        case .constellation: ConstellationBackground()
        }
    }

    // MARK: - Clock

    @ViewBuilder
    private func clockView(for style: ClockStyle, date: Date) -> some View {
        switch style {
        case .spectrum: ClockSpectrum(date: date)
        case .neon:     ClockNeon(date: date)
        case .sunrise:  ClockSunrise(date: date)
        case .void:     ClockVoid(date: date)
        case .crystal:  ClockCrystal(date: date)
        }
    }
}
