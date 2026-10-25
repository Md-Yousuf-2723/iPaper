import SwiftUI

public struct RecentWallpapersView: View {
    @ObservedObject var appState: AppState
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        if !appState.recentWallpapers.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Recent Wallpapers")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(appState.recentWallpapers) { video in
                            let isCurrent = appState.selectedVideo?.fileURL == video.fileURL
                            Button {
                                appState.applyRecentWallpaper(video)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Image(systemName: "film")
                                            .foregroundColor(isCurrent ? .accentColor : .secondary)
                                        Spacer()
                                        if isCurrent && appState.isPlaying {
                                            Text("Active")
                                                .font(.system(size: 9, weight: .bold))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.green.opacity(0.18))
                                                .foregroundColor(.green)
                                                .clipShape(Capsule())
                                        }
                                    }
                                    
                                    Text(video.fileName)
                                        .font(.system(size: 12, weight: .medium))
                                        .lineLimit(1)
                                    
                                    HStack(spacing: 6) {
                                        Text(video.formattedDuration)
                                        Text("•")
                                        Text(video.codecName)
                                    }
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                }
                                .padding(10)
                                .frame(width: 170, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(isCurrent ? Color.accentColor.opacity(0.08) : Color(nsColor: .controlBackgroundColor).opacity(0.5))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(isCurrent ? Color.accentColor.opacity(0.5) : Color.secondary.opacity(0.15), lineWidth: 1)
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }
}
