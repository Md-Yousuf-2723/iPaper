import SwiftUI
import AppKit

public struct MainWindowView: View {
    @ObservedObject var appState: AppState
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Glossy Header Bar
            headerView
            
            // Content Area
            ScrollView {
                VStack(spacing: 22) {
                    // Error message alert banner
                    if let error = appState.errorMessage {
                        errorBanner(error)
                    }
                    
                    // Main Video Import / Preview
                    if let video = appState.selectedVideo {
                        VideoPreviewView(metadata: video) {
                            appState.selectedVideo = nil
                        }
                    } else {
                        DropZoneView(appState: appState)
                    }
                    
                    // Display Selector
                    DisplaySelectorView(appState: appState)
                    
                    // Recent Wallpapers
                    RecentWallpapersView(appState: appState)
                }
                .padding(24)
            }
            
            // Glossy Bottom Action Bar
            bottomActionBar
        }
        .frame(minWidth: 540, idealWidth: 600, minHeight: 600, idealHeight: 660)
        .background(
            ZStack {
                Color(nsColor: .windowBackgroundColor)
                LinearGradient(
                    colors: [
                        Color.accentColor.opacity(0.04),
                        Color.clear,
                        Color.accentColor.opacity(0.02)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack(spacing: 14) {
            // Logo Image with glossy frame
            ZStack {
                if let logoImg = loadLogoImage() {
                    Image(nsImage: logoImg)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.4), Color.white.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
                } else {
                    Image(systemName: "sparkles.tv")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.accentColor)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text("iPaper")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    
                    // Status Badge
                    if appState.isPlaying {
                        HStack(spacing: 5) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6.5, height: 6.5)
                            Text("Active")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color.green.opacity(0.14))
                                .overlay(Capsule().stroke(Color.green.opacity(0.35), lineWidth: 0.8))
                        )
                    }
                }
                
                Text("Native macOS Live Wallpaper")
                    .font(.system(size: 11.5, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Launch at login indicator
            Toggle(isOn: Binding(
                get: { appState.launchAtLogin },
                set: { _ in appState.toggleLaunchAtLogin() }
            )) {
                Text("Launch at Login")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
            .toggleStyle(.checkbox)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 1),
                    alignment: .bottom
                )
        )
    }
    
    // MARK: - Error Banner
    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            Text(message)
                .font(.system(size: 12.5, weight: .medium, design: .rounded))
                .foregroundColor(.red)
            Spacer()
            Button {
                appState.errorMessage = nil
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.red.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Bottom Action Bar
    private var bottomActionBar: some View {
        HStack {
            if appState.isPlaying {
                Button(role: .destructive) {
                    appState.stopWallpaper()
                } label: {
                    Label("Stop Wallpaper", systemImage: "stop.fill")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
            }
            
            Spacer()
            
            Button {
                appState.applyCurrentWallpaper()
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 15))
                    Text("Apply Live Wallpaper")
                        .font(.system(size: 13.5, weight: .semibold, design: .rounded))
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 7)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .disabled(appState.selectedVideo == nil)
            .shadow(color: appState.selectedVideo != nil ? Color.accentColor.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 3)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 1),
                    alignment: .top
                )
        )
    }
    
    private func loadLogoImage() -> NSImage? {
        if let path = Bundle.main.path(forResource: "logo_app", ofType: "png") {
            return NSImage(contentsOfFile: path)
        }
        let fallbackPath = "Assets/logo_app.png"
        if FileManager.default.fileExists(atPath: fallbackPath) {
            return NSImage(contentsOfFile: fallbackPath)
        }
        return nil
    }
}
