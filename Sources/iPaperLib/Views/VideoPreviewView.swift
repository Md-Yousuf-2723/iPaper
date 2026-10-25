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
            // Preview Player with glossy frame
            ZStack(alignment: .bottomTrailing) {
                AVPlayerRepresentable(player: model.player)
                    .frame(height: 230)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.35), Color.white.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 6)
                
                HStack(spacing: 8) {
                    Button {
                        model.togglePlay()
                    } label: {
                        Image(systemName: model.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(9)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .overlay(
                                Circle().stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        onClear()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                            .padding(9)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .overlay(
                                Circle().stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .help("Choose different video")
                }
                .padding(12)
            }
            
            // Video Details Chips
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(metadata.fileName)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                        .truncationMode(.middle)
                    
                    Spacer()
                    
                    Text(metadata.codecName)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 3.5)
                        .background(
                            Capsule()
                                .fill(Color.accentColor.opacity(0.15))
                                .overlay(Capsule().stroke(Color.accentColor.opacity(0.35), lineWidth: 1))
                        )
                        .foregroundColor(.accentColor)
                }
                
                HStack(spacing: 10) {
                    cozyBadge(icon: "aspectratio", text: metadata.formattedResolution)
                    cozyBadge(icon: "clock.fill", text: metadata.formattedDuration)
                    cozyBadge(icon: "speedometer", text: metadata.formattedFrameRate)
                    cozyBadge(icon: "internaldrive.fill", text: metadata.formattedFileSize)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.35), Color.white.opacity(0.06)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)
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
    
    private func cozyBadge(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            Text(text)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.06))
                .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.8))
        )
    }
}

public struct AVPlayerRepresentable: NSViewRepresentable {
    public let player: AVPlayer?
    
    public init(player: AVPlayer?) {
        self.player = player
    }
    
    public func makeNSView(context: Context) -> AVPlayerView {
        let view = AVPlayerView()
        view.controlsStyle = .none
        view.videoGravity = .resizeAspectFill
        view.player = player
        return view
    }
    
    public func updateNSView(_ nsView: AVPlayerView, context: Context) {
        nsView.player = player
    }
}
