import AppKit
import AVFoundation

public final class VideoPlayerView: NSView {
    private let playerLayer = AVPlayerLayer()
    
    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.frame = bounds
        layer?.addSublayer(playerLayer)
    }
    
    public func setPlayer(_ player: AVPlayer?) {
        playerLayer.player = player
    }
    
    public override func layout() {
        super.layout()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        playerLayer.frame = bounds
        CATransaction.commit()
    }
}
