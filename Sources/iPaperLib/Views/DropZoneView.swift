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
                    .fill(isTargeted ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.08))
                    .frame(width: 64, height: 64)
                
                Image(systemName: isTargeted ? "arrow.down.circle.fill" : "video.badge.plus")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .foregroundColor(isTargeted ? .accentColor : .secondary)
            }
            .animation(.easeInOut(duration: 0.2), value: isTargeted)
            
            VStack(spacing: 6) {
                Text(isTargeted ? "Drop MOV video here" : "Drag & Drop your .mov video here")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("QuickTime MOV files encoded in H.264, HEVC, or Apple ProRes")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Button {
                openFilePicker()
            } label: {
                Label("Browse MOV Video...", systemImage: "folder")
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    isTargeted ? Color.accentColor : Color.secondary.opacity(0.25),
                    style: StrokeStyle(lineWidth: 2, dash: isTargeted ? [] : [6, 6])
                )
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isTargeted ? Color.accentColor.opacity(0.05) : Color(nsColor: .windowBackgroundColor).opacity(0.5))
                )
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
        panel.allowedContentTypes = [UTType.quickTimeMovie]
        panel.prompt = "Select Video"
        panel.message = "Choose a .mov video file for your live wallpaper"
        
        if panel.runModal() == .OK, let url = panel.url {
            Task { @MainActor in
                await appState.selectFile(url: url)
            }
        }
    }
}
