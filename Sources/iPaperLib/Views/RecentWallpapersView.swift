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
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(appState.recentWallpapers) { video in
                            let isCurrent = appState.selectedVideo?.fileURL == video.fileURL
                            Button {
                                appState.applyRecentWallpaper(video)
                            } label: {
                                VStack(alignment: .leading, spacing: 5) {
                                    HStack {
                                        Image(systemName: "film.stack.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(isCurrent ? .accentColor : .secondary)
                                        Spacer()
                                        if isCurrent && appState.isPlaying {
                                            Text("Active")
                                                .font(.system(size: 9.5, weight: .bold, design: .rounded))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.green.opacity(0.18))
                                                .foregroundColor(.green)
                                                .clipShape(Capsule())
                                                .overlay(Capsule().stroke(Color.green.opacity(0.4), lineWidth: 0.8))
                                        }
                                    }
                                    
                                    Text(video.fileName)
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                    
                                    HStack(spacing: 5) {
                                        Text(video.formattedDuration)
                                        Text("•")
                                        Text(video.codecName)
                                    }
                                    .font(.system(size: 10, weight: .regular, design: .rounded))
                                    .foregroundColor(.secondary)
                                }
                                .padding(11)
                                .frame(width: 175, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(isCurrent ? Color.accentColor.opacity(0.1) : Color.white.opacity(0.04))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(
                                                    LinearGradient(
                                                        colors: [
                                                            isCurrent ? Color.accentColor.opacity(0.8) : Color.white.opacity(0.2),
                                                            isCurrent ? Color.accentColor.opacity(0.2) : Color.white.opacity(0.04)
                                                        ],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ),
                                                    lineWidth: 1
                                                )
                                        )
                                        .shadow(color: isCurrent ? Color.accentColor.opacity(0.1) : Color.black.opacity(0.02), radius: 6, x: 0, y: 2)
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
