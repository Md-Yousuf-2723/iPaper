import Foundation
import AVFoundation
import CoreMedia

public enum VideoValidationError: LocalizedError, Equatable {
    case fileDoesNotExist(URL)
    case unsupportedFormat(URL)
    case unreadableFile(String)
    case noVideoTrackFound
    case unsupportedCodec(String)
    case unplayableMedia(String)
    
    public var errorDescription: String? {
        switch self {
        case .fileDoesNotExist(let url):
            return "File does not exist at: \(url.lastPathComponent)"
        case .unsupportedFormat:
            return "Only .mov and .mp4 video files are supported. Please select a valid .mov or .mp4 file."
        case .unreadableFile(let msg):
            return "Unable to read video file: \(msg)"
        case .noVideoTrackFound:
            return "The selected video file does not contain any playable video stream."
        case .unsupportedCodec(let codec):
            return "Unsupported video codec '\(codec)'. iPaper supports H.264, HEVC (H.265), and Apple ProRes video files."
        case .unplayableMedia(let reason):
            return "This media cannot be played by macOS: \(reason)"
        }
    }
}

public struct VideoValidator: Sendable {
    public init() {}
    
    public func validate(url: URL) async throws -> VideoMetadata {
        // 1. Verify file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw VideoValidationError.fileDoesNotExist(url)
        }
        
        // 2. Verify extension is MOV or MP4
        let ext = url.pathExtension.lowercased()
        guard ext == "mov" || ext == "mp4" else {
            throw VideoValidationError.unsupportedFormat(url)
        }
        
        // 3. Inspect file attributes
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = (attributes?[.size] as? NSNumber)?.int64Value ?? 0
        
        // 4. Create AVAsset
        let asset = AVURLAsset(url: url)
        
        let isPlayable: Bool
        do {
            isPlayable = try await asset.load(.isPlayable)
        } catch {
            throw VideoValidationError.unreadableFile(error.localizedDescription)
        }
        
        guard isPlayable else {
            throw VideoValidationError.unplayableMedia("File is corrupted or not decodable.")
        }
        
        // 5. Load video tracks
        let videoTracks: [AVAssetTrack]
        do {
            videoTracks = try await asset.loadTracks(withMediaType: .video)
        } catch {
            throw VideoValidationError.unreadableFile(error.localizedDescription)
        }
        
        guard let track = videoTracks.first else {
            throw VideoValidationError.noVideoTrackFound
        }
        
        // 6. Inspect track properties
        let naturalSize = try await track.load(.naturalSize)
        let frameRate = try await track.load(.nominalFrameRate)
        let durationCMTime = try await asset.load(.duration)
        let durationSeconds = CMTimeGetSeconds(durationCMTime)
        
        // 7. Inspect Codec
        let formatDescriptions = try await track.load(.formatDescriptions)
        var codecName = ext == "mp4" ? "MP4 Video" : "MOV Video"
        
        if let desc = formatDescriptions.first {
            let subType = CMFormatDescriptionGetMediaSubType(desc)
            codecName = formatCodecName(for: subType, ext: ext)
        }
        
        let width = Int(abs(naturalSize.width))
        let height = Int(abs(naturalSize.height))
        
        guard width > 0, height > 0 else {
            throw VideoValidationError.unplayableMedia("Invalid video frame dimensions.")
        }
        
        return VideoMetadata(
            fileURL: url,
            fileName: url.lastPathComponent,
            fileSize: fileSize,
            width: width,
            height: height,
            durationSeconds: durationSeconds,
            frameRate: frameRate > 0 ? frameRate : 30.0,
            codecName: codecName
        )
    }
    
    private func formatCodecName(for code: FourCharCode, ext: String) -> String {
        switch code {
        case kCMVideoCodecType_H264:
            return "H.264 / AVC"
        case kCMVideoCodecType_HEVC:
            return "HEVC / H.265"
        case kCMVideoCodecType_AppleProRes422:
            return "Apple ProRes 422"
        case kCMVideoCodecType_AppleProRes4444:
            return "Apple ProRes 4444"
        case kCMVideoCodecType_AppleProRes422HQ:
            return "Apple ProRes 422 HQ"
        case kCMVideoCodecType_AppleProRes422LT:
            return "Apple ProRes 422 LT"
        case kCMVideoCodecType_AppleProRes422Proxy:
            return "Apple ProRes 422 Proxy"
        default:
            let fourCC = String(format: "%c%c%c%c",
                (code >> 24) & 0xff,
                (code >> 16) & 0xff,
                (code >> 8) & 0xff,
                code & 0xff
            ).trimmingCharacters(in: .whitespaces)
            return fourCC.isEmpty ? (ext == "mp4" ? "MPEG-4 Video" : "QuickTime Video") : fourCC.uppercased()
        }
    }
}
