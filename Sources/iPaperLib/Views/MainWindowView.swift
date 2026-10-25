import SwiftUI
import AppKit

public struct MainWindowView: View {
    @ObservedObject var appState: AppState
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            headerView
            
            Divider()
            
            ScrollView {
                VStack(spacing: 20) {
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
                    
                    // Destination Selector
                    destinationSelector
                    
                    // Recent Wallpapers
                    RecentWallpapersView(appState: appState)
                }
                .padding(24)
            }
            
            Divider()
            
            // Bottom Action Bar
            bottomActionBar
        }
        .frame(minWidth: 540, idealWidth: 600, minHeight: 650, idealHeight: 700)
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack(spacing: 12) {
            // Logo Image
            if let logoImg = loadLogoImage() {
                Image(nsImage: logoImg)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Image(systemName: "sparkles.tv")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .foregroundColor(.accentColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text("iPaper")
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    // Status Badge
                    if appState.isPlaying {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 7, height: 7)
                            Text("Wallpaper Active")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.green.opacity(0.12))
                        .clipShape(Capsule())
                    }
                }
                
                Text("Native macOS Live Video Wallpaper")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Launch at login indicator
            Toggle(isOn: Binding(
                get: { appState.launchAtLogin },
                set: { _ in appState.toggleLaunchAtLogin() }
            )) {
                Text("Launch at Login")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .toggleStyle(.checkbox)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Destination Selector
    private var destinationSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Destination")
                .font(.subheadline)
                .fontWeight(.medium)
            
            HStack(spacing: 12) {
                // Desktop Option (Active)
                HStack(spacing: 8) {
                    Image(systemName: "menubar.dock.rectangle")
                        .foregroundColor(.accentColor)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Desktop Wallpaper")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Renders behind desktop windows & icons")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                }
                .padding(10)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.accentColor.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.accentColor.opacity(0.5), lineWidth: 1)
                        )
                )
                
                // Lock Screen Option (Disabled with explanation)
                HStack(spacing: 8) {
                    Image(systemName: "lock.laptopcomputer")
                        .foregroundColor(.secondary)
                    VStack(alignment: .leading, spacing: 1) {
                        HStack(spacing: 4) {
                            Text("Lock Screen")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary)
                            Text("Restricted")
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(Color.secondary.opacity(0.15))
                                .foregroundColor(.secondary)
                                .clipShape(Capsule())
                        }
                        Text("macOS isolates lock screen for security")
                            .font(.caption2)
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                    Spacer()
                }
                .padding(10)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.secondary.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
                        )
                )
                .help("Apple macOS isolates the Lock Screen inside system daemons without public live wallpaper APIs.")
            }
        }
    }
    
    // MARK: - Error Banner
    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.red)
            Spacer()
            Button {
                appState.errorMessage = nil
            } label: {
                Image(systemName: "xmark")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.red.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
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
                        .padding(.horizontal, 8)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            
            Spacer()
            
            Button {
                appState.applyCurrentWallpaper()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "play.circle.fill")
                    Text("Apply Live Wallpaper")
                }
                .fontWeight(.semibold)
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(appState.selectedVideo == nil)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial)
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
