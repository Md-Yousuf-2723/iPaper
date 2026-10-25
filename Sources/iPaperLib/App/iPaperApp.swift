import SwiftUI
import AppKit

public struct iPaperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState.shared
    
    public init() {}
    
    public var body: some Scene {
        MenuBarExtra {
            MenuBarPopoverView(appState: appState) {
                appDelegate.showMainWindow()
            }
        } label: {
            Image(systemName: appState.isPlaying ? "sparkles.tv.fill" : "sparkles.tv")
        }
        .menuBarExtraStyle(.window)
        
        Settings {
            EmptyView()
        }
    }
}
