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
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(appState.availableDisplays.count) Display\(appState.availableDisplays.count == 1 ? "" : "s") Detected")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 10) {
                // All Displays Option
                displayCard(
                    title: "All Displays",
                    subtitle: "Synchronized",
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
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(isSelected ? .accentColor : .secondary)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.accentColor)
                    }
                }
                
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color(nsColor: .controlBackgroundColor).opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.2), lineWidth: isSelected ? 1.5 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
