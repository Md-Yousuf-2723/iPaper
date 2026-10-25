# iPaper

<p align="center">
  <img src="Assets/logo_app.png" alt="iPaper Logo" width="128" height="128">
</p>

## Overview

**iPaper** is a native macOS application that allows users to apply live video wallpapers (`.mov` and `.mp4`) to their Mac desktops smoothly and efficiently. Designed specifically for Apple Silicon Macs, it delivers hardware-accelerated playback with minimal resource consumption.

## System Architecture

- **Desktop Window Layering**: Operates at WindowServer layer `kCGDesktopIconWindowLevelKey - 1` (`-2147483604`). Videos render seamlessly behind Finder desktop icons, allowing mouse clicks, window movements, and drag-and-drop operations to pass through unhindered.
- **Hardware-Accelerated Decoding**: Utilizes AVFoundation and Apple Silicon's hardware Media Engine (H.264, HEVC, and Apple ProRes) for smooth continuous playback without unnecessary CPU overhead.
- **Background Persistence**: Closing the configuration window or closing the app from the Dock dynamically switches the application to background accessory mode. The live wallpaper continues uninterrupted and the status control remains active in the top-right menu bar.

## Homebrew Installation

```bash
brew tap Md-Yousuf-2723/tap
brew install --cask ipaper
```

## Homebrew Uninstallation

To completely remove iPaper and all associated files (preferences, caches, and saved states):

```bash
brew uninstall --zap --cask ipaper
```
