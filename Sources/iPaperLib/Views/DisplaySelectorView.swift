import SwiftUI

public struct DisplaySelectorView: View {
    @ObservedObject var appState: AppState
    
    public init(appState: AppState) {
        self.appState = appState
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Target Display")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(appState.availableDisplays.count) Display\(appState.availableDisplays.count == 1 ? "" : "s") Connected")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 12) {
                // All Displays Option
                displayCard(
                    title: "All Displays",
                    subtitle: "Synchronized playback",
                    icon: "display.2",
                    isSelected: appState.targetDisplayID == nil
                ) {
                    appState.targetDisplayID = nil
                }
                
                // Individual Displays
                ForEach(appState.availableDisplays) { display in
                    displayCard(
                        title: display.displayTitle,
                        subtitle: display.resolutionString,
                        icon: display.isMain ? "laptopcomputer" : "display",
                        isSelected: appState.targetDisplayID == display.id
                    ) {
                        appState.targetDisplayID = display.id
                    }
                }
            }
        }
    }
    
    private func displayCard(title: String, subtitle: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(isSelected ? Color.accentColor.opacity(0.2) : Color.white.opacity(0.08))
                            .frame(width: 28, height: 28)
                        Image(systemName: icon)
                            .font(.system(size: 13))
                            .foregroundColor(isSelected ? .accentColor : .secondary)
                    }
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.accentColor)
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(subtitle)
                        .font(.system(size: 10.5, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
            .padding(11)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.accentColor.opacity(0.12) : Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        isSelected ? Color.accentColor.opacity(0.8) : Color.white.opacity(0.2),
                                        isSelected ? Color.accentColor.opacity(0.3) : Color.white.opacity(0.04)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: isSelected ? 1.5 : 1
                            )
                    )
                    .shadow(color: isSelected ? Color.accentColor.opacity(0.15) : Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
