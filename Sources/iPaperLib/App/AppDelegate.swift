import AppKit
import SwiftUI

@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    public static private(set) var shared: AppDelegate?
    public var isExplicitQuit = false
    private var mainWindowController: NSWindowController?
    
    public override init() {
        super.init()
        Self.shared = self
    }
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Listen for system shutdown / reboot to allow clean termination
        NotificationCenter.default.addObserver(
            forName: NSWorkspace.willPowerOffNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.isExplicitQuit = true
            }
        }
        
        NSApplication.shared.setActivationPolicy(.regular)
        showMainWindow()
    }
    
    public func showMainWindow() {
        NSApplication.shared.setActivationPolicy(.regular)
        
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
        window.delegate = self
        
        let controller = NSWindowController(window: window)
        self.mainWindowController = controller
        
        window.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    public func closeMainWindow() {
        if let controller = mainWindowController, let window = controller.window {
            window.orderOut(nil)
        }
        // Transition to accessory: removes the icon from the Dock while keeping the menu bar icon & wallpaper alive!
        NSApplication.shared.setActivationPolicy(.accessory)
    }
    
    // MARK: - NSWindowDelegate
    public func windowWillClose(_ notification: Notification) {
        // When main window is closed via red close button or Cmd+W:
        // Transition to accessory so Dock icon is removed, leaving menu bar icon & wallpaper playing
        NSApplication.shared.setActivationPolicy(.accessory)
    }
    
    // MARK: - Application Lifecycle
    public func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            showMainWindow()
        }
        return true
    }
    
    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Closing the main window must NEVER terminate the app or stop live wallpaper playback!
        return false
    }
    
    public func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if isExplicitQuit {
            return .terminateNow
        }
        
        // When quitting from Dock or pressing Cmd+Q:
        // Dismiss the main window and remove the Dock icon,
        // but KEEP the live wallpaper playing and the menu bar icon active in the top right corner!
        closeMainWindow()
        return .terminateCancel
    }
    
    public func forceQuit() {
        isExplicitQuit = true
        WallpaperEngine.shared.stop()
        NSApplication.shared.terminate(nil)
    }
    
    public func applicationWillTerminate(_ notification: Notification) {
        WallpaperEngine.shared.stop()
    }
}
