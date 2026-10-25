import Foundation
import AppKit

public struct DisplayInfo: Identifiable, Equatable, Hashable, Sendable {
    public let id: CGDirectDisplayID
    public let name: String
    public let frame: CGRect
    public let isMain: Bool
    public let isBuiltin: Bool
    public let scaleFactor: CGFloat
    
    public init(id: CGDirectDisplayID, name: String, frame: CGRect, isMain: Bool, isBuiltin: Bool = false, scaleFactor: CGFloat) {
        self.id = id
        self.name = name
        self.frame = frame
        self.isMain = isMain
        self.isBuiltin = isBuiltin
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
        let mainID = CGMainDisplayID()
        return NSScreen.screens.compactMap { screen in
            guard let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
                return nil
            }
            let displayID = CGDirectDisplayID(screenNumber.uint32Value)
            let isMain = (displayID == mainID)
            let isBuiltin = (CGDisplayIsBuiltin(displayID) != 0)
            return DisplayInfo(
                id: displayID,
                name: screen.localizedName,
                frame: screen.frame,
                isMain: isMain,
                isBuiltin: isBuiltin,
                scaleFactor: screen.backingScaleFactor
            )
        }
    }
}
