import AppKit
import MoleWidgetCore
import SwiftUI

@main
struct MoleWidgetApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @AppStorage(WidgetSettings.positionLockedKey) private var positionLocked = false

    var body: some Scene {
        MenuBarExtra("mole-widget", systemImage: "chart.bar.fill") {
            Toggle("Lock position", isOn: $positionLocked)
            Divider()
            Button("Quit mole-widget") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}

/// Returns whether the widget can be dragged at this moment.
private var isDraggingAllowed: Bool {
    !UserDefaults.standard.bool(forKey: WidgetSettings.positionLockedKey)
}

/// NSHostingView for the widget:
/// - mouseDownCanMoveWindow == false disables AppKit's built-in auto-drag
///   (it would ignore the lock — inner SwiftUI views report "can move");
///   dragging goes ONLY through DesktopWindow.mouseDown;
/// - acceptsFirstMouse == true so the lock button responds on the very first
///   click even though the window never becomes key.
final class WidgetHostingView<Content: View>: NSHostingView<Content> {
    override var mouseDownCanMoveWindow: Bool { false }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}

/// Borderless desktop-level window: never steals focus,
/// draggable from anywhere (unless position is locked).
final class DesktopWindow: NSWindow {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    override func mouseDown(with event: NSEvent) {
        // Drag only on left button and only when position is not locked;
        // everything else uses the standard handler (right-click etc. are not swallowed)
        if event.type == .leftMouseDown, isDraggingAllowed {
            performDrag(with: event)
        } else {
            super.mouseDown(with: event)
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: DesktopWindow?
    private let store = MetricsStore()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory) // no Dock icon
        store.start()

        let window = DesktopWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 300),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        // One level ABOVE the Finder desktop icon window, but still below normal windows.
        // Below the icons (like Übersicht), mouse events never reach the widget: Finder's
        // transparent full-screen desktop window intercepts all clicks, making the
        // widget impossible to drag.
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) + 1)
        // Visible on all Spaces, stationary in Mission Control, excluded from cmd-tab
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        let hostingView = WidgetHostingView(rootView: WidgetRootView(store: store))
        window.contentView = hostingView
        // Fit the window exactly to its content: extra transparent area
        // would capture clicks outside the visible widget
        let fitting = hostingView.fittingSize
        if fitting.width > 0, fitting.height > 0 {
            window.setContentSize(fitting)
        }

        // Idiomatic order: set default position first (center),
        // then autosave — it will overwrite with the saved frame if one exists
        window.center()
        window.setFrameAutosaveName("MoleWidgetWindow")

        window.orderFrontRegardless()
        self.window = window
    }

    func applicationWillTerminate(_ notification: Notification) {
        store.stop()
    }
}
