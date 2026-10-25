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
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                if appState.isPlaying {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        Text("Active")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.12))
                    .clipShape(Capsule())
                } else {
                    Text("Paused")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Current Video Card
            if let current = appState.selectedVideo {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Current Live Wallpaper")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(current.fileName)
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Text(current.codecName)
                        Text("•")
                        Text(current.formattedDuration)
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(nsColor: .controlBackgroundColor).opacity(0.6))
                )
            }
            
            // Playback controls
            HStack(spacing: 8) {
                if appState.isPlaying {
                    Button {
                        appState.stopWallpaper()
                    } label: {
                        Label("Stop Wallpaper", systemImage: "stop.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                } else if appState.selectedVideo != nil {
                    Button {
                        appState.applyCurrentWallpaper()
                    } label: {
                        Label("Start Wallpaper", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            
            // Recent Wallpapers Quick Picker
            if !appState.recentWallpapers.isEmpty {
                Divider()
                
                Text("Recent")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 4) {
                    ForEach(Array(appState.recentWallpapers.prefix(3))) { item in
                        Button {
                            appState.applyRecentWallpaper(item)
                        } label: {
                            HStack {
                                Image(systemName: "film")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(item.fileName)
                                    .font(.system(size: 12))
                                    .lineLimit(1)
                                Spacer()
                                if appState.selectedVideo?.fileURL == item.fileURL && appState.isPlaying {
                                    Image(systemName: "checkmark")
                                        .font(.caption)
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
                        Text("Open iPaper Window")
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 6)
                }
                .buttonStyle(.plain)
                
                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    HStack {
                        Image(systemName: "power")
                        Text("Quit iPaper")
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
