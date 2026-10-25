import AppKit

public final class WallpaperWindow: NSWindow {
    public let playerView: VideoPlayerView
    public let displayID: CGDirectDisplayID
    
    public init(screen: NSScreen, displayID: CGDirectDisplayID) {
        self.displayID = displayID
        self.playerView = VideoPlayerView(frame: screen.frame)
        
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false,
            screen: screen
        )
        
        setupWindow()
    }
    
    public override init(
        contentRect: NSRect,
        styleMask style: NSWindow.StyleMask,
        backing backingStoreType: NSWindow.BackingStoreType,
        defer flag: Bool
    ) {
        self.displayID = 0
        self.playerView = VideoPlayerView(frame: contentRect)
        super.init(contentRect: contentRect, styleMask: [.borderless], backing: backingStoreType, defer: flag)
        setupWindow()
    }
    
    private func setupWindow() {
        // Window level: right behind Finder desktop icons and above the desktop picture
        let desktopIconLevel = Int(CGWindowLevelForKey(.desktopIconWindow))
        self.level = NSWindow.Level(rawValue: desktopIconLevel - 1)
        
        // Collection behaviors: join all spaces, stationary, ignore Cmd-` cycle
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        self.isOpaque = true
        self.hasShadow = false
        self.ignoresMouseEvents = true
        self.canHide = false
        self.backgroundColor = .black
        self.contentView = playerView
    }
    
    public func updateFrame(to newFrame: NSRect) {
        self.setFrame(newFrame, display: true)
        self.playerView.frame = NSRect(origin: .zero, size: newFrame.size)
    }
}
