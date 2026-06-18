import SwiftUI
import AppKit

/// NSWindowController that hosts the SwiftUI preferences panel.
/// Accepts ClockSettings as a reference so preference changes are applied
/// reactively without any view teardown. Dismisses via NSApp.endSheet
/// (not window.close) to avoid the Settings app freeze.
class PreferencesWindowController: NSWindowController {

    init(settings: ClockSettings) {
        // Build a dismiss closure that runs on the next run-loop turn to avoid
        // calling NSApp.endSheet from within a SwiftUI action handler.
        let window = NSWindow()

        super.init(window: window)

        let dismiss: () -> Void = { [weak window] in
            DispatchQueue.main.async {
                guard let win = window else { return }
                if let parent = win.sheetParent {
                    parent.endSheet(win)
                }
                win.orderOut(nil)
            }
        }

        let prefsView = PreferencesView(settings: settings, dismiss: dismiss)
        let hosting = NSHostingController(rootView: prefsView)
        hosting.preferredContentSize = NSSize(width: 580, height: 400)

        window.contentViewController = hosting
        window.title = "ClockLock Options"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.center()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
