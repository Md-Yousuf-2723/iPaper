import SwiftUI
import UniformTypeIdentifiers
import AppKit

public struct DropZoneView: View {
    @ObservedObject var appState: AppState
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        let isTargeted = appState.isDropTargeted
        
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                isTargeted ? Color.accentColor.opacity(0.3) : Color.white.opacity(0.12),
                                isTargeted ? Color.accentColor.opacity(0.1) : Color.white.opacity(0.03)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 68, height: 68)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        isTargeted ? Color.accentColor : Color.white.opacity(0.25),
                                        isTargeted ? Color.accentColor.opacity(0.3) : Color.white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: isTargeted ? Color.accentColor.opacity(0.3) : Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
                
                Image(systemName: isTargeted ? "arrow.down.circle.fill" : "video.badge.plus")
                    .font(.system(size: 28, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(isTargeted ? .accentColor : .primary)
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isTargeted)
            
            VStack(spacing: 5) {
                Text(isTargeted ? "Drop Video to Apply" : "Drag & Drop Live Wallpaper")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("Supports .mov and .mp4 (H.264, HEVC, Apple ProRes)")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            Button {
                openFilePicker()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 12))
                    Text("Browse Video Files...")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 7)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .shadow(color: Color.accentColor.opacity(0.2), radius: 5, x: 0, y: 2)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 210)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    isTargeted ? Color.accentColor : Color.white.opacity(0.25),
                                    isTargeted ? Color.accentColor.opacity(0.4) : Color.white.opacity(0.06)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: isTargeted ? 2 : 1.5, dash: isTargeted ? [] : [6, 6])
                        )
                )
                .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
        )
        .onDrop(of: [.fileURL], isTargeted: Binding(
            get: { appState.isDropTargeted },
            set: { appState.isDropTargeted = $0 }
        )) { providers in
            guard let provider = providers.first else { return false }
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                if let url = url {
                    Task { @MainActor in
                        await appState.selectFile(url: url)
                    }
                }
            }
            return true
        }
    }
    
    private func openFilePicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [UTType.quickTimeMovie, UTType.mpeg4Movie]
        panel.prompt = "Select Video"
        panel.message = "Choose a .mov or .mp4 video for your live wallpaper"
        
        if panel.runModal() == .OK, let url = panel.url {
            Task { @MainActor in
                await appState.selectFile(url: url)
            }
        }
    }
}
