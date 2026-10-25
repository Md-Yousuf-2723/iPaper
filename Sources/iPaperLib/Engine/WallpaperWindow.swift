import AppKit

public final class WallpaperWindow: NSWindow {
    public let playerView: VideoPlayerView
    public let displayID: CGDirectDisplayID
    
    public init(screen: NSScreen, displayID: CGDirectDisplayID) {
        self.displayID = displayID
        let localBounds = NSRect(origin: .zero, size: screen.frame.size)
        self.playerView = VideoPlayerView(frame: localBounds)
        
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        self.setFrame(screen.frame, display: true)
        setupWindow()
    }
    
    public override init(
        contentRect: NSRect,
        styleMask style: NSWindow.StyleMask,
        backing backingStoreType: NSWindow.BackingStoreType,
        defer flag: Bool
    ) {
        self.displayID = 0
        let localBounds = NSRect(origin: .zero, size: contentRect.size)
        self.playerView = VideoPlayerView(frame: localBounds)
        super.init(contentRect: contentRect, styleMask: [.borderless], backing: backingStoreType, defer: flag)
        self.setFrame(contentRect, display: true)
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
        self.isReleasedWhenClosed = false
        self.backgroundColor = .black
        self.contentView = playerView
        self.playerView.frame = NSRect(origin: .zero, size: self.frame.size)
        self.playerView.autoresizingMask = [.width, .height]
    }
    
    public func prepareForTeardown() {
        self.playerView.prepareForTeardown()
        self.contentView = nil
    }
    
    public func updateFrame(to newFrame: NSRect) {
        self.setFrame(newFrame, display: true)
        self.playerView.frame = NSRect(origin: .zero, size: newFrame.size)
    }
}
