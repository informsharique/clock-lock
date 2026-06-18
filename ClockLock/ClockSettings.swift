import Foundation
import Combine

/// Shared observable settings object. Passed as an environmentObject so
/// preferences changes automatically propagate to the running SwiftUI view
/// without recreating the NSHostingView (which caused the Settings freeze).
class ClockSettings: ObservableObject {
    @Published var clockStyle: ClockStyle = .spectrum
    @Published var backgroundStyle: BackgroundStyle = .aurora

    private let defaults = UserDefaults(suiteName: "com.clocklock.screensaver")

    init() {
        loadPreferences()
    }

    func loadPreferences() {
        if let raw = defaults?.string(forKey: "clockStyle"),
           let style = ClockStyle(rawValue: raw) {
            clockStyle = style
        }
        if let raw = defaults?.string(forKey: "backgroundStyle"),
           let style = BackgroundStyle(rawValue: raw) {
            backgroundStyle = style
        }
    }

    func savePreferences() {
        defaults?.set(clockStyle.rawValue, forKey: "clockStyle")
        defaults?.set(backgroundStyle.rawValue, forKey: "backgroundStyle")
    }
}
