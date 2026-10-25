import Foundation
import CoreGraphics

public struct VideoMetadata: Identifiable, Codable, Equatable, Sendable {
    public var id: String { fileURL.path }
    public let fileURL: URL
    public let fileName: String
    public let fileSize: Int64
    public let width: Int
    public let height: Int
    public let durationSeconds: Double
    public let frameRate: Float
    public let codecName: String
    public let addedAt: Date
    
    public init(
        fileURL: URL,
        fileName: String,
        fileSize: Int64,
        width: Int,
        height: Int,
        durationSeconds: Double,
        frameRate: Float,
        codecName: String,
        addedAt: Date = Date()
    ) {
        self.fileURL = fileURL
        self.fileName = fileName
        self.fileSize = fileSize
        self.width = width
        self.height = height
        self.durationSeconds = durationSeconds
        self.frameRate = frameRate
        self.codecName = codecName
        self.addedAt = addedAt
    }
    
    public var formattedDuration: String {
        let totalSeconds = Int(durationSeconds.rounded())
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    public var formattedFileSize: String {
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = [.useMB, .useGB]
        bcf.countStyle = .file
        return bcf.string(fromByteCount: fileSize)
    }
    
    public var formattedResolution: String {
        let gcd = greatestCommonDivisor(width, height)
        let aspectW = gcd > 0 ? width / gcd : 0
        let aspectH = gcd > 0 ? height / gcd : 0
        return "\(width) × \(height) (\(aspectW):\(aspectH))"
    }
    
    public var formattedFrameRate: String {
        return String(format: "%.0f fps", frameRate)
    }
    
    private func greatestCommonDivisor(_ a: Int, _ b: Int) -> Int {
        var x = abs(a)
        var y = abs(b)
        while y != 0 {
            let temp = y
            y = x % y
            x = temp
        }
        return x
    }
}
