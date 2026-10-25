import Foundation
import AppKit
import ServiceManagement

@MainActor
public final class AppState: ObservableObject {
    public static let shared = AppState()
    
    @Published public var selectedVideo: VideoMetadata?
    @Published public var recentWallpapers: [VideoMetadata] = []
    @Published public var availableDisplays: [DisplayInfo] = []
    @Published public var targetDisplayID: CGDirectDisplayID? = nil // nil = All Displays
    @Published public var isApplying: Bool = false
    @Published public var errorMessage: String? = nil
    @Published public var isPlaying: Bool = false
    @Published public var launchAtLogin: Bool = false
    @Published public var isDropTargeted: Bool = false
    
    private let validator = VideoValidator()
    private let engine = WallpaperEngine.shared
    
    private let recentsKey = "iPaper.recentWallpapers.v1"
    private let lastVideoPathKey = "iPaper.lastVideoPath"
    private let lastDisplayKey = "iPaper.lastDisplayID"
    
    public init() {
        refreshDisplays()
        loadPersistedState()
        checkLaunchAtLoginStatus()
        
        // Listen for screen changes
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshDisplays()
            }
        }
    }
    
    public func refreshDisplays() {
        self.availableDisplays = DisplayInfo.currentDisplays()
        // If current targetDisplayID is no longer connected, reset to nil (all displays)
        if let target = targetDisplayID, !availableDisplays.contains(where: { $0.id == target }) {
            self.targetDisplayID = nil
        }
    }
    
    public func selectFile(url: URL) async {
        isApplying = true
        errorMessage = nil
        
        do {
            let metadata = try await validator.validate(url: url)
            self.selectedVideo = metadata
            addToRecents(metadata)
        } catch let error as LocalizedError {
            self.errorMessage = error.errorDescription ?? error.localizedDescription
        } catch {
            self.errorMessage = "Failed to load video: \(error.localizedDescription)"
        }
        
        isApplying = false
    }
    
    public func applyCurrentWallpaper() {
        guard let video = selectedVideo else { return }
        errorMessage = nil
        
        engine.apply(videoURL: video.fileURL, forDisplayID: targetDisplayID)
        isPlaying = engine.isPlaying
        
        UserDefaults.standard.set(video.fileURL.path, forKey: lastVideoPathKey)
        if let target = targetDisplayID {
            UserDefaults.standard.set(target, forKey: lastDisplayKey)
        } else {
            UserDefaults.standard.removeObject(forKey: lastDisplayKey)
        }
    }
    
    public func applyRecentWallpaper(_ video: VideoMetadata) {
        self.selectedVideo = video
        applyCurrentWallpaper()
    }
    
    public func stopWallpaper() {
        engine.stop(displayID: targetDisplayID)
        isPlaying = engine.isPlaying
        UserDefaults.standard.removeObject(forKey: lastVideoPathKey)
    }
    
    public func stopAllWallpapers() {
        engine.stop(displayID: nil)
        isPlaying = false
        UserDefaults.standard.removeObject(forKey: lastVideoPathKey)
    }
    
    private func addToRecents(_ item: VideoMetadata) {
        var recents = recentWallpapers.filter { $0.fileURL != item.fileURL }
        recents.insert(item, at: 0)
        if recents.count > 10 {
            recents = Array(recents.prefix(10))
        }
        self.recentWallpapers = recents
        saveRecents()
    }
    
    private func saveRecents() {
        if let data = try? JSONEncoder().encode(recentWallpapers) {
            UserDefaults.standard.set(data, forKey: recentsKey)
        }
    }
    
    private func loadPersistedState() {
        if let data = UserDefaults.standard.data(forKey: recentsKey),
           let items = try? JSONDecoder().decode([VideoMetadata].self, from: data) {
            // Keep items that still exist on disk
            self.recentWallpapers = items.filter { FileManager.default.fileExists(atPath: $0.fileURL.path) }
        }
        
        if let savedPath = UserDefaults.standard.string(forKey: lastVideoPathKey) {
            let url = URL(fileURLWithPath: savedPath)
            if FileManager.default.fileExists(atPath: savedPath) {
                Task {
                    await selectFile(url: url)
                    // Auto-restore active wallpaper
                    self.applyCurrentWallpaper()
                }
            }
        }
    }
    
    public func toggleLaunchAtLogin() {
        if #available(macOS 13.0, *) {
            do {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                    launchAtLogin = false
                } else {
                    try SMAppService.mainApp.register()
                    launchAtLogin = true
                }
            } catch {
                print("[AppState] Error toggling launch at login: \(error)")
            }
        }
    }
    
    private func checkLaunchAtLoginStatus() {
        if #available(macOS 13.0, *) {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}
