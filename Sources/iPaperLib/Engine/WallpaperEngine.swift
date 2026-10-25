import AppKit
import AVFoundation

@MainActor
public final class WallpaperEngine: ObservableObject {
    public static let shared = WallpaperEngine()
    
    @Published public private(set) var isPlaying: Bool = false
    @Published public private(set) var activeWallpapers: [CGDirectDisplayID: URL] = [:]
    
    private var windows: [CGDirectDisplayID: WallpaperWindow] = [:]
    private var players: [CGDirectDisplayID: AVQueuePlayer] = [:]
    private var loopers: [CGDirectDisplayID: AVPlayerLooper] = [:]
    
    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    public func apply(videoURL: URL, forDisplayID targetDisplayID: CGDirectDisplayID? = nil) {
        guard FileManager.default.fileExists(atPath: videoURL.path) else {
            print("[WallpaperEngine] Video file not found: \(videoURL.path)")
            return
        }
        
        let screens = NSScreen.screens
        
        for screen in screens {
            guard let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
                continue
            }
            let displayID = CGDirectDisplayID(screenNumber.uint32Value)
            
            // If target display is specified and doesn't match this screen, skip
            if let target = targetDisplayID, target != displayID {
                continue
            }
            
            applyToScreen(screen, displayID: displayID, videoURL: videoURL)
        }
        
        isPlaying = !windows.isEmpty
    }
    
    private func applyToScreen(_ screen: NSScreen, displayID: CGDirectDisplayID, videoURL: URL) {
        // Stop existing player on this screen if any
        stopScreen(displayID: displayID)
        
        let playerItem = AVPlayerItem(url: videoURL)
        let queuePlayer = AVQueuePlayer(playerItem: playerItem)
        queuePlayer.isMuted = true
        queuePlayer.volume = 0.0
        queuePlayer.actionAtItemEnd = .none
        
        // Loop continuously with zero hitch
        let looper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
        
        // Create or configure window
        let window = WallpaperWindow(screen: screen, displayID: displayID)
        window.playerView.setPlayer(queuePlayer)
        window.orderFrontRegardless()
        
        queuePlayer.play()
        
        windows[displayID] = window
        players[displayID] = queuePlayer
        loopers[displayID] = looper
        activeWallpapers[displayID] = videoURL
        
        print("[WallpaperEngine] Applied wallpaper on display \(displayID): \(videoURL.lastPathComponent)")
    }
    
    public func isWallpaperActive(on displayID: CGDirectDisplayID) -> Bool {
        return windows[displayID] != nil
    }
    
    public func stop(displayID: CGDirectDisplayID? = nil) {
        if let displayID = displayID {
            stopScreen(displayID: displayID)
        } else {
            for id in Array(windows.keys) {
                stopScreen(displayID: id)
            }
        }
        isPlaying = !windows.isEmpty
    }
    
    private func stopScreen(displayID: CGDirectDisplayID) {
        // 1. Disable and remove looper first to avoid KVO conflicts on player mutation
        if let looper = loopers[displayID] {
            looper.disableLooping()
        }
        loopers.removeValue(forKey: displayID)
        
        // 2. Safely pause and clear queue items
        if let player = players[displayID] {
            player.pause()
            player.removeAllItems()
        }
        players.removeValue(forKey: displayID)
        
        // 3. Tear down view hierarchy and order out without calling destructive window.close()
        if let window = windows[displayID] {
            window.prepareForTeardown()
            window.orderOut(nil)
        }
        windows.removeValue(forKey: displayID)
        activeWallpapers.removeValue(forKey: displayID)
    }
    
    @objc private func screenParametersChanged() {
        print("[WallpaperEngine] Screen parameters changed, re-evaluating displays...")
        let currentScreens = NSScreen.screens
        var validIDs = Set<CGDirectDisplayID>()
        
        for screen in currentScreens {
            guard let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
                continue
            }
            let displayID = CGDirectDisplayID(screenNumber.uint32Value)
            validIDs.insert(displayID)
            
            if let window = windows[displayID] {
                // Screen still exists, update frame in case resolution or position changed
                window.updateFrame(to: screen.frame)
            } else if let savedURL = activeWallpapers[displayID] {
                // If this display didn't have a window yet but has an active wallpaper assigned
                applyToScreen(screen, displayID: displayID, videoURL: savedURL)
            }
        }
        
        // Clean up disconnected screens
        for oldID in Array(windows.keys) {
            if !validIDs.contains(oldID) {
                print("[WallpaperEngine] Display \(oldID) was disconnected, removing wallpaper window.")
                stopScreen(displayID: oldID)
            }
        }
        
        isPlaying = !windows.isEmpty
    }
}
