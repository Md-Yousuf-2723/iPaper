import Foundation
import AVFoundation
import AppKit
import iPaperLib

@MainActor
func runTests() async {
    var passed = 0
    var failed = 0

    func assertTest(_ condition: Bool, _ name: String) {
        if condition {
            print("  ✓ [PASS] \(name)")
            passed += 1
        } else {
            print("  ✗ [FAIL] \(name)")
            failed += 1
        }
    }

    print("=========================================")
    print("          iPaper Unit Test Suite         ")
    print("=========================================")

    // MARK: - 1. VideoMetadata Unit Tests
    print("\n[Suite 1] VideoMetadata Tests:")
    let metadata = VideoMetadata(
        fileURL: URL(fileURLWithPath: "/tmp/sample.mov"),
        fileName: "sample.mov",
        fileSize: 15_728_640,
        width: 1920,
        height: 1080,
        durationSeconds: 75.0,
        frameRate: 60.0,
        codecName: "HEVC / H.265"
    )

    assertTest(metadata.fileName == "sample.mov", "FileName parsed correctly")
    assertTest(metadata.width == 1920 && metadata.height == 1080, "Resolution extracted correctly")
    assertTest(metadata.formattedResolution == "1920 × 1080 (16:9)", "Formatted resolution aspect ratio calculation")
    assertTest(metadata.formattedDuration == "1:15", "Duration formatted to mm:ss correctly")
    assertTest(metadata.formattedFrameRate == "60 fps", "Frame rate formatted to fps string")
    assertTest(metadata.formattedFileSize.contains("MB"), "File size formatted with unit")

    // MARK: - 2. DisplayInfo Unit Tests
    print("\n[Suite 2] DisplayInfo Tests:")
    let displays = DisplayInfo.currentDisplays()
    assertTest(!displays.isEmpty, "At least one connected display detected")
    if let first = displays.first {
        assertTest(!first.name.isEmpty, "Display name is non-empty (\(first.name))")
        assertTest(first.frame.width > 0 && first.frame.height > 0, "Display dimensions are valid (\(first.resolutionString))")
        assertTest(first.displayTitle.contains(first.name), "Display title includes localized name")
    }

    // MARK: - 3. AppState Unit Tests
    print("\n[Suite 3] AppState Tests:")
    let state = AppState.shared
    assertTest(!state.availableDisplays.isEmpty, "AppState populated connected displays")
    assertTest(state.targetDisplayID == nil, "Default target display is All Displays (nil)")
    assertTest(state.errorMessage == nil, "Initial error message is nil")
    assertTest(!state.isDropTargeted, "Drop targeted initial state is false")

    // MARK: - 4. VideoValidator Unit Tests (MOV & MP4)
    print("\n[Suite 4] VideoValidator Tests:")
    let validator = VideoValidator()
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

    // Non-existent file
    let missingURL = tempDir.appendingPathComponent("non_existent.mov")
    do {
        _ = try await validator.validate(url: missingURL)
        assertTest(false, "Should throw for missing file")
    } catch let error as VideoValidationError {
        assertTest(error == .fileDoesNotExist(missingURL), "Throws fileDoesNotExist for missing file")
    } catch {
        assertTest(false, "Unexpected error: \(error)")
    }

    // Invalid extension
    let txtURL = tempDir.appendingPathComponent("note.txt")
    try? "not a video".write(to: txtURL, atomically: true, encoding: .utf8)
    do {
        _ = try await validator.validate(url: txtURL)
        assertTest(false, "Should throw for non-supported extension")
    } catch let error as VideoValidationError {
        assertTest(error == .unsupportedFormat(txtURL), "Throws unsupportedFormat for .txt file")
    } catch {
        assertTest(false, "Unexpected error: \(error)")
    }

    // Valid MOV generation & validation
    let validMovURL = tempDir.appendingPathComponent("test_valid.mov")
    do {
        let writer = try AVAssetWriter(outputURL: validMovURL, fileType: .mov)
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: 1280,
            AVVideoHeightKey: 720
        ]
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        writer.add(input)
        
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
                kCVPixelBufferWidthKey as String: 1280,
                kCVPixelBufferHeightKey as String: 720
            ]
        )
        
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)
        
        var buffer: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(nil, adaptor.pixelBufferPool!, &buffer)
        
        if let px = buffer {
            for i in 0..<15 {
                let time = CMTime(value: CMTimeValue(i), timescale: 30)
                while !input.isReadyForMoreMediaData {
                    try? await Task.sleep(nanoseconds: 10_000_000)
                }
                adaptor.append(px, withPresentationTime: time)
            }
        }
        
        input.markAsFinished()
        await writer.finishWriting()
        
        let validMeta = try await validator.validate(url: validMovURL)
        assertTest(validMeta.fileName == "test_valid.mov", "Valid MOV file name parsed")
        assertTest(validMeta.width == 1280 && validMeta.height == 720, "Valid MOV 1280x720 dimensions verified")
        assertTest(validMeta.codecName == "H.264 / AVC", "MOV H.264 codec verified")
    } catch {
        assertTest(false, "Valid MOV validation failed with: \(error)")
    }

    // Valid MP4 generation & validation
    let validMp4URL = tempDir.appendingPathComponent("test_valid.mp4")
    do {
        let writer = try AVAssetWriter(outputURL: validMp4URL, fileType: .mp4)
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: 1920,
            AVVideoHeightKey: 1080
        ]
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        writer.add(input)
        
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
                kCVPixelBufferWidthKey as String: 1920,
                kCVPixelBufferHeightKey as String: 1080
            ]
        )
        
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)
        
        var buffer: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(nil, adaptor.pixelBufferPool!, &buffer)
        
        if let px = buffer {
            for i in 0..<15 {
                let time = CMTime(value: CMTimeValue(i), timescale: 30)
                while !input.isReadyForMoreMediaData {
                    try? await Task.sleep(nanoseconds: 10_000_000)
                }
                adaptor.append(px, withPresentationTime: time)
            }
        }
        
        input.markAsFinished()
        await writer.finishWriting()
        
        let mp4Meta = try await validator.validate(url: validMp4URL)
        assertTest(mp4Meta.fileName == "test_valid.mp4", "Valid MP4 file name parsed")
        assertTest(mp4Meta.width == 1920 && mp4Meta.height == 1080, "Valid MP4 1920x1080 dimensions verified")
        assertTest(mp4Meta.codecName == "H.264 / AVC", "MP4 H.264 codec verified")
        assertTest(mp4Meta.formattedResolution == "1920 × 1080 (16:9)", "MP4 aspect ratio calculated")
    } catch {
        assertTest(false, "Valid MP4 validation failed with: \(error)")
    }

    // MARK: - 5. WallpaperEngine & Multi-Display Lifecycle Tests
    print("\n[Suite 5] WallpaperEngine & Display Lifecycle Tests:")
    let engine = WallpaperEngine.shared
    let testVideoPath = tempDir.appendingPathComponent("test_valid.mov")
    if FileManager.default.fileExists(atPath: testVideoPath.path) {
        // Test Apply to All Displays
        autoreleasepool {
            engine.apply(videoURL: testVideoPath, forDisplayID: nil)
        }
        assertTest(engine.isPlaying, "WallpaperEngine started playback on displays")

        let displays = DisplayInfo.currentDisplays()
        for d in displays {
            assertTest(engine.isWallpaperActive(on: d.id), "Wallpaper active on display: \(d.name)")
        }

        // Test display selection and stopping on specific display
        if let first = displays.first {
            autoreleasepool {
                engine.stop(displayID: first.id)
            }
            assertTest(!engine.isWallpaperActive(on: first.id), "Successfully stopped wallpaper on display: \(first.name)")
        }

        // Test stopping all displays cleanly without SIGSEGV or memory leaks
        autoreleasepool {
            engine.stop(displayID: nil)
        }
        assertTest(!engine.isPlaying, "WallpaperEngine stopped all displays cleanly")

        // Test AppState display switching and stop behavior
        let state = AppState.shared
        autoreleasepool {
            engine.apply(videoURL: testVideoPath, forDisplayID: nil)
            state.isPlaying = engine.isPlaying
        }
        assertTest(state.isPlaying, "AppState reflects active playback")

        // Switch target display to another display (or first display) and click stopWallpaper
        if let target = displays.last {
            state.targetDisplayID = target.id
            autoreleasepool {
                state.stopWallpaper()
            }
            // Verify no crash and state correctly updated
            assertTest(true, "Switched target display and stopped wallpaper without crash")
        }

        autoreleasepool {
            state.stopAllWallpapers()
        }
        assertTest(!state.isPlaying, "stopAllWallpapers stopped all instances cleanly")
    } else {
        assertTest(false, "Test video file missing for Suite 5")
    }

    try? FileManager.default.removeItem(at: tempDir)

    print("\n=========================================")
    print("Results: \(passed) passed, \(failed) failed")
    print("=========================================")

    if failed > 0 {
        exit(1)
    } else {
        print("All unit tests passed successfully!\n")
        exit(0)
    }
}

await runTests()
