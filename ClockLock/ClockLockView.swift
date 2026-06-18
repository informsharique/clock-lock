import ScreenSaver
import AppKit
import SwiftUI

/// The main entry point for the ClockLock screen saver.
/// Uses a single persistent NSHostingView; style changes are propagated via
/// ClockSettings (ObservableObject + environmentObject) so the view never
/// needs to be torn down — eliminating the Settings freeze on Apply.
@objc(ClockLockView)
class ClockLockView: ScreenSaverView {

    // MARK: - Properties

    private let settings = ClockSettings()
    private var hostingView: NSHostingView<AnyView>?
    private var preferencesController: PreferencesWindowController?

    // MARK: - Initialization

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        settings.loadPreferences()
        setupHostingView()
        animationTimeInterval = 1.0 / 60.0
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        settings.loadPreferences()
    }

    private func setupHostingView() {
        let rootView = AnyView(
            ClockHostView()
                .environmentObject(settings)
        )
        let hosting = NSHostingView(rootView: rootView)
        hosting.frame = bounds
        hosting.autoresizingMask = NSView.AutoresizingMask([.width, .height])
        addSubview(hosting)
        self.hostingView = hosting
    }

    override func animateOneFrame() {
        // SwiftUI drives its own animations; intentionally empty.
    }

    override var hasConfigureSheet: Bool { true }

    override var configureSheet: NSWindow? {
        // Return a new controller each time (required by ScreenSaverKit).
        // Retain the controller so it is not deallocated immediately.
        let controller = PreferencesWindowController(settings: settings)
        self.preferencesController = controller
        return controller.window
    }
}
