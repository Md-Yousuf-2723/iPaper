import AppKit
import SwiftUI

@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var mainWindowController: NSWindowController?
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.regular)
        showMainWindow()
    }
    
    public func showMainWindow() {
        if let controller = mainWindowController, let window = controller.window {
            window.makeKeyAndOrderFront(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
            return
        }
        
        let contentView = MainWindowView(appState: AppState.shared)
        let hostingController = NSHostingController(rootView: contentView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 720),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "iPaper"
        window.contentViewController = hostingController
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 540, height: 600)
        
        let controller = NSWindowController(window: window)
        self.mainWindowController = controller
        
        window.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    public func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            showMainWindow()
        }
        return true
    }
    
    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Critical: closing the main window must NEVER terminate the app or stop live wallpaper playback!
        return false
    }
    
    public func applicationWillTerminate(_ notification: Notification) {
        // Safe cleanup when quitting
        WallpaperEngine.shared.stop()
    }
}
