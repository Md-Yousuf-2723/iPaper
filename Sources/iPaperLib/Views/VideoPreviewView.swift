import SwiftUI
import AVKit
import AVFoundation

@MainActor
public final class PreviewPlayerModel: ObservableObject {
    @Published public var player: AVPlayer?
    @Published public var isPlaying: Bool = true
    
    public init() {}
    
    public func setup(with url: URL) {
        teardown()
        let p = AVPlayer(url: url)
        p.isMuted = true
        p.actionAtItemEnd = .none
        
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: p.currentItem,
            queue: .main
        ) { [weak p] _ in
            p?.seek(to: .zero)
            p?.play()
        }
        
        p.play()
        self.player = p
        self.isPlaying = true
    }
    
    public func teardown() {
        player?.pause()
        player = nil
    }
    
    public func togglePlay() {
        guard let p = player else { return }
        if isPlaying {
            p.pause()
            isPlaying = false
        } else {
            p.play()
            isPlaying = true
        }
    }
}

public struct VideoPreviewView: View {
    let metadata: VideoMetadata
    let onClear: () -> Void
    
    @StateObject private var model = PreviewPlayerModel()
    
    public init(metadata: VideoMetadata, onClear: @escaping () -> Void) {
        self.metadata = metadata
        self.onClear = onClear
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Preview Player
            ZStack(alignment: .bottomTrailing) {
                AVPlayerRepresentable(player: model.player)
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                
                HStack(spacing: 8) {
                    Button {
                        model.togglePlay()
                    } label: {
                        Image(systemName: model.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        onClear()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help("Choose different video")
                }
                .padding(10)
            }
            
            // Video Details Chips
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(metadata.fileName)
                        .font(.headline)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    
                    Spacer()
                    
                    Text(metadata.codecName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.accentColor.opacity(0.12))
                        .foregroundColor(.accentColor)
                        .clipShape(Capsule())
                }
                
                HStack(spacing: 12) {
                    badge(icon: "aspectratio", text: metadata.formattedResolution)
                    badge(icon: "clock", text: metadata.formattedDuration)
                    badge(icon: "speedometer", text: metadata.formattedFrameRate)
                    badge(icon: "internaldrive", text: metadata.formattedFileSize)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                )
        )
        .onAppear {
            model.setup(with: metadata.fileURL)
        }
        .onDisappear {
            model.teardown()
        }
        .onChange(of: metadata.fileURL) { _, newURL in
            model.setup(with: newURL)
        }
    }
    
    private func badge(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct AVPlayerRepresentable: NSViewRepresentable {
    let player: AVPlayer?
    
    func makeNSView(context: Context) -> AVPlayerView {
        let view = AVPlayerView()
        view.controlsStyle = .none
        view.videoGravity = .resizeAspectFill
        view.player = player
        return view
    }
    
    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        nsView.player = player
    }
}
