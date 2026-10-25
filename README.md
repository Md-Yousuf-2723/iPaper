# iPaper

<p align="center">
  <img src="Assets/logo_app.png" alt="iPaper Logo" width="128" height="128">
</p>

## Overview

**iPaper** is a native macOS application that allows users to apply live video wallpapers (`.mov` and `.mp4`) to their Mac desktops smoothly and efficiently. Designed specifically for Apple Silicon Macs, it delivers hardware-accelerated playback with minimal resource consumption.

## System Architecture

For Mac m1, m2, m3, m4 and later apple chips

## Installation

### 1. Check if Homebrew is Installed

Run this command in Terminal to check if Homebrew is installed:

```bash
brew --version
```

### 2. If Homebrew is Installed

Run:

```bash
brew tap md-yousuf-2723/tap
brew trust md-yousuf-2723/tap
brew install --cask ipaper
```

### 3. If Homebrew is Not Installed

First, install Homebrew:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Then, install iPaper:

```bash
brew tap md-yousuf-2723/tap
brew trust md-yousuf-2723/tap
brew install --cask ipaper
```

### Trust & Security (Gatekeeper)

Because iPaper is an independent open-source project and not distributed through the Mac App Store, macOS Gatekeeper may display an "unidentified developer" prompt. 

You can install and trust it directly using Homebrew's `--no-quarantine` flag:

```bash
brew install --cask --no-quarantine ipaper
```

If already installed and blocked by Gatekeeper, allow it to run with:

```bash
xattr -cr /Applications/iPaper.app
```

> **Verification:** Every release binary is cryptographically verified by Homebrew against an immutable SHA-256 checksum to guarantee authenticity and prevent tampering.

## Homebrew Update

To update iPaper to the latest version at any time:

```bash
brew upgrade --cask ipaper
```

## Homebrew Uninstallation

To completely remove iPaper and all associated files (preferences, caches, and saved states):

```bash
brew uninstall --zap --cask ipaper
```
