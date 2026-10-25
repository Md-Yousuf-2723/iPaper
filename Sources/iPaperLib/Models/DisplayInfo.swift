import Foundation
import AppKit

public struct DisplayInfo: Identifiable, Equatable, Hashable, Sendable {
    public let id: CGDirectDisplayID
    public let name: String
    public let frame: CGRect
    public let isMain: Bool
    public let scaleFactor: CGFloat
    
    public init(id: CGDirectDisplayID, name: String, frame: CGRect, isMain: Bool, scaleFactor: CGFloat) {
        self.id = id
        self.name = name
        self.frame = frame
        self.isMain = isMain
        self.scaleFactor = scaleFactor
    }
    
    public var resolutionString: String {
        let w = Int(frame.width)
        let h = Int(frame.height)
        return "\(w) × \(h)"
    }
    
    public var displayTitle: String {
        if isMain {
            return "\(name) (Main Display)"
        }
        return name
    }
    
    @MainActor
    public static func currentDisplays() -> [DisplayInfo] {
        return NSScreen.screens.compactMap { screen in
            guard let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
                return nil
            }
            let displayID = CGDirectDisplayID(screenNumber.uint32Value)
            let isMain = screen == NSScreen.main
            return DisplayInfo(
                id: displayID,
                name: screen.localizedName,
                frame: screen.frame,
                isMain: isMain,
                scaleFactor: screen.backingScaleFactor
            )
        }
    }
}
