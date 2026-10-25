import SwiftUI
import AppKit

public struct MenuBarPopoverView: View {
    @ObservedObject var appState: AppState
    let onOpenMainWindow: () -> Void
    
    public init(appState: AppState, onOpenMainWindow: @escaping () -> Void) {
        self.appState = appState
        self.onOpenMainWindow = onOpenMainWindow
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("iPaper")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                
                Spacer()
                
                if appState.isPlaying {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        Text("Active")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2.5)
                    .background(Color.green.opacity(0.14))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.green.opacity(0.35), lineWidth: 0.8))
                } else {
                    Text("Paused")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
            
            // Current Video Card
            if let current = appState.selectedVideo {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Current Live Wallpaper")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    Text(current.fileName)
                        .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                    
                    HStack(spacing: 6) {
                        Text(current.codecName)
                        Text("•")
                        Text(current.formattedDuration)
                    }
                    .font(.system(size: 10.5, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
                }
                .padding(9)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                )
            }
            
            // Playback controls
            HStack(spacing: 8) {
                if appState.isPlaying {
                    Button {
                        appState.stopWallpaper()
                    } label: {
                        Label("Stop Wallpaper", systemImage: "stop.fill")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                } else if appState.selectedVideo != nil {
                    Button {
                        appState.applyCurrentWallpaper()
                    } label: {
                        Label("Start Wallpaper", systemImage: "play.fill")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            
            // Recent Wallpapers Quick Picker
            if !appState.recentWallpapers.isEmpty {
                Divider()
                
                Text("Recent")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
                
                VStack(spacing: 4) {
                    ForEach(Array(appState.recentWallpapers.prefix(3))) { item in
                        Button {
                            appState.applyRecentWallpaper(item)
                        } label: {
                            HStack {
                                Image(systemName: "film")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                Text(item.fileName)
                                    .font(.system(size: 11.5, weight: .medium, design: .rounded))
                                    .lineLimit(1)
                                Spacer()
                                if appState.selectedVideo?.fileURL == item.fileURL && appState.isPlaying {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 6)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            Divider()
            
            // Actions
            VStack(spacing: 4) {
                Button {
                    onOpenMainWindow()
                } label: {
                    HStack {
                        Image(systemName: "macwindow")
                            .font(.system(size: 12))
                        Text("Open iPaper Window")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 6)
                }
                .buttonStyle(.plain)
                
                Button {
                    AppDelegate.shared?.forceQuit()
                } label: {
                    HStack {
                        Image(systemName: "power")
                            .font(.system(size: 12))
                        Text("Quit iPaper")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 6)
                    .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .frame(width: 260)
    }
}
