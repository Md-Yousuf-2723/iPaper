import SwiftUI
import AppKit
import AVFoundation

@MainActor
public final class MenuBarViewModel: ObservableObject {
    @Published public var activeDisplayID: CGDirectDisplayID
    @Published public var hoveredVideo: VideoMetadata? = nil
    @Published public var previewPlayer: AVQueuePlayer? = nil
    @Published public var currentPreviewURL: URL? = nil
    
    private var looper: AVPlayerLooper?
    
    public init() {
        let mouseLoc = NSEvent.mouseLocation
        if let screen = NSScreen.screens.first(where: { NSMouseInRect(mouseLoc, $0.frame, false) }),
           let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber {
            self.activeDisplayID = CGDirectDisplayID(screenNumber.uint32Value)
        } else {
            self.activeDisplayID = CGMainDisplayID()
        }
    }
    
    public func refreshActiveDisplay() {
        let mouseLoc = NSEvent.mouseLocation
        if let screen = NSScreen.screens.first(where: { NSMouseInRect(mouseLoc, $0.frame, false) }),
           let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber {
            let id = CGDirectDisplayID(screenNumber.uint32Value)
            self.activeDisplayID = id
            return
        }
        self.activeDisplayID = CGMainDisplayID()
    }
    
    public func updatePreview(for url: URL?) {
        guard let url = url, FileManager.default.fileExists(atPath: url.path) else {
            teardownPreview()
            return
        }
        
        if currentPreviewURL == url && previewPlayer != nil {
            return
        }
        
        teardownPreview()
        self.currentPreviewURL = url
        
        let item = AVPlayerItem(url: url)
        let player = AVQueuePlayer(playerItem: item)
        player.isMuted = true
        player.volume = 0.0
        player.actionAtItemEnd = .none
        
        self.looper = AVPlayerLooper(player: player, templateItem: item)
        player.play()
        self.previewPlayer = player
    }
    
    public func teardownPreview() {
        if let looper = looper {
            looper.disableLooping()
        }
        looper = nil
        if let player = previewPlayer {
            player.pause()
            player.removeAllItems()
        }
        previewPlayer = nil
        currentPreviewURL = nil
    }
}

public struct MenuBarPopoverView: View {
    @ObservedObject var appState: AppState
    let onOpenMainWindow: () -> Void
    
    @StateObject private var viewModel = MenuBarViewModel()
    
    public init(appState: AppState, onOpenMainWindow: @escaping () -> Void) {
        self.appState = appState
        self.onOpenMainWindow = onOpenMainWindow
    }
    
    private var activeScreenName: String {
        if let display = appState.availableDisplays.first(where: { $0.id == viewModel.activeDisplayID }) {
            return display.name
        }
        return "Current Display"
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles.tv.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.accentColor)
                    Text("iPaper")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                }
                
                Spacer()
                
                let isDisplayActive = appState.isWallpaperActive(on: viewModel.activeDisplayID)
                HStack(spacing: 4) {
                    Circle()
                        .fill(isDisplayActive ? Color.green : Color.secondary)
                        .frame(width: 6, height: 6)
                    Text(isDisplayActive ? "Active" : "Idle")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(isDisplayActive ? .green : .secondary)
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 2.5)
                .background(isDisplayActive ? Color.green.opacity(0.14) : Color.white.opacity(0.06))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(isDisplayActive ? Color.green.opacity(0.35) : Color.white.opacity(0.1), lineWidth: 0.8))
            }
            
            // Multi-Display Selector Pills (Works for 2, 3, 4 or more displays)
            if appState.availableDisplays.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(appState.availableDisplays) { display in
                            let isSelected = viewModel.activeDisplayID == display.id
                            Button {
                                viewModel.activeDisplayID = display.id
                                viewModel.hoveredVideo = nil
                                let activeURL = appState.activeWallpaperURL(for: display.id)
                                viewModel.updatePreview(for: activeURL)
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: display.isBuiltin ? "laptopcomputer" : "display")
                                        .font(.system(size: 10))
                                    Text(display.name)
                                        .font(.system(size: 11, weight: isSelected ? .semibold : .regular, design: .rounded))
                                        .lineLimit(1)
                                    if appState.isWallpaperActive(on: display.id) {
                                        Circle()
                                            .fill(Color.green)
                                            .frame(width: 5, height: 5)
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.white.opacity(0.04))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(isSelected ? Color.accentColor.opacity(0.7) : Color.white.opacity(0.1), lineWidth: 1)
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            
            // Video Preview Area (Shows live preview of active wallpaper, or hovered recent wallpaper)
            previewSection
            
            // Recent Wallpapers Picker
            recentsSection
            
            Divider()
            
            // Bottom Action Links
            HStack {
                Button {
                    onOpenMainWindow()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "macwindow")
                            .font(.system(size: 11))
                        Text("Open Window")
                            .font(.system(size: 11.5, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button {
                    AppDelegate.shared?.forceQuit()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "power")
                            .font(.system(size: 11))
                        Text("Quit")
                            .font(.system(size: 11.5, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(.red.opacity(0.85))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .frame(width: 290)
        .onAppear {
            viewModel.refreshActiveDisplay()
            let activeURL = appState.activeWallpaperURL(for: viewModel.activeDisplayID)
            viewModel.updatePreview(for: activeURL)
        }
        .onDisappear {
            viewModel.teardownPreview()
        }
    }
    
    // MARK: - Preview Section
    private var previewSection: some View {
        let activeURL = appState.activeWallpaperURL(for: viewModel.activeDisplayID)
        let activeMeta = appState.activeWallpaperMetadata(for: viewModel.activeDisplayID)
        let isHovering = viewModel.hoveredVideo != nil
        
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(isHovering ? "Preview (Hovered)" : "Current: \(activeScreenName)")
                    .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if !isHovering && activeURL != nil {
                    Button(role: .destructive) {
                        appState.stopWallpaper(on: viewModel.activeDisplayID)
                        viewModel.updatePreview(for: nil)
                    } label: {
                        Text("Stop")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            if viewModel.previewPlayer != nil {
                ZStack(alignment: .bottomLeading) {
                    AVPlayerRepresentable(player: viewModel.previewPlayer)
                        .frame(height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.3), Color.white.opacity(0.06)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
                    
                    // Video Info Overlay
                    let title = viewModel.hoveredVideo?.fileName ?? activeMeta?.fileName ?? activeURL?.lastPathComponent ?? ""
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .shadow(color: .black.opacity(0.8), radius: 3, x: 0, y: 1)
                        
                        if isHovering {
                            Text("Click below to apply to \(activeScreenName)")
                                .font(.system(size: 9.5, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.85))
                                .shadow(color: .black.opacity(0.8), radius: 3, x: 0, y: 1)
                        }
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        LinearGradient(
                            colors: [Color.clear, Color.black.opacity(0.75)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    )
                }
            } else {
                // Empty state card
                VStack(spacing: 6) {
                    Image(systemName: "sparkles.tv")
                        .font(.system(size: 22))
                        .foregroundColor(.secondary.opacity(0.7))
                    Text("No wallpaper active on \(activeScreenName)")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                    Text("Hover over recent videos below to preview")
                        .font(.system(size: 9.5, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 100)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.03))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                )
            }
        }
    }
    
    // MARK: - Recents Section
    private var recentsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Recent Wallpapers")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(appState.recentWallpapers.count)")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary.opacity(0.7))
            }
            
            if appState.recentWallpapers.isEmpty {
                Text("No recent wallpapers yet")
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 6)
            } else {
                VStack(spacing: 3) {
                    ForEach(Array(appState.recentWallpapers.prefix(4))) { item in
                        let isPlayingOnCurrent = appState.activeWallpaperURL(for: viewModel.activeDisplayID) == item.fileURL
                        let isHovered = viewModel.hoveredVideo?.fileURL == item.fileURL
                        
                        Button {
                            appState.applyWallpaper(item, toDisplayID: viewModel.activeDisplayID)
                            viewModel.hoveredVideo = nil
                            viewModel.updatePreview(for: item.fileURL)
                        } label: {
                            HStack(spacing: 7) {
                                Image(systemName: "film.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(isPlayingOnCurrent ? .accentColor : (isHovered ? .primary : .secondary))
                                
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(item.fileName)
                                        .font(.system(size: 11.5, weight: isPlayingOnCurrent ? .semibold : .medium, design: .rounded))
                                        .foregroundColor(isPlayingOnCurrent ? .primary : (isHovered ? .primary : .secondary))
                                        .lineLimit(1)
                                    
                                    HStack(spacing: 4) {
                                        Text(item.formattedDuration)
                                        Text("•")
                                        Text(item.codecName)
                                    }
                                    .font(.system(size: 9.5, weight: .regular, design: .rounded))
                                    .foregroundColor(.secondary.opacity(0.8))
                                }
                                
                                Spacer()
                                
                                if isPlayingOnCurrent {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.accentColor)
                                }
                                
                                Button {
                                    appState.removeFromRecents(item)
                                    if viewModel.hoveredVideo?.fileURL == item.fileURL {
                                        viewModel.hoveredVideo = nil
                                        let activeURL = appState.activeWallpaperURL(for: viewModel.activeDisplayID)
                                        viewModel.updatePreview(for: activeURL)
                                    }
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(.secondary.opacity(0.7))
                                        .padding(4)
                                }
                                .buttonStyle(.plain)
                                .help("Remove from recents")
                            }
                            .padding(.vertical, 5)
                            .padding(.horizontal, 7)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(isHovered ? Color.white.opacity(0.08) : (isPlayingOnCurrent ? Color.accentColor.opacity(0.08) : Color.clear))
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .onHover { hovering in
                            if hovering {
                                viewModel.hoveredVideo = item
                                viewModel.updatePreview(for: item.fileURL)
                            } else if viewModel.hoveredVideo?.fileURL == item.fileURL {
                                viewModel.hoveredVideo = nil
                                let activeURL = appState.activeWallpaperURL(for: viewModel.activeDisplayID)
                                viewModel.updatePreview(for: activeURL)
                            }
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                appState.removeFromRecents(item)
                            } label: {
                                Label("Remove from Recents", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
    }
}
