# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.4.2] - 2025-11-30

### Fixed
- **Android Compilation Error**: Fixed missing `setEnableMomentum` method implementation in `PdfManager.java` that was causing build failures with React Native codegen. The method is now implemented as a NOOP since Android's ScrollView handles momentum scrolling automatically.

## [3.4.1] - 2025-11-29

### Fixed
- Android and iOS build issues resolved

## [3.4.0] - 2025-11-29

### Added
- **Enhanced Navigation**: Added immediate page navigation support in `setPage()` method. The PDF now jumps to the specified page instantly when navigation is triggered programmatically.
- **Improved File Path Handling**: Added `downloadedFilePath` instance variable for reliable path tracking during PDF loading. This ensures file paths are available immediately, even before React state updates.
- **New `getPath()` Method**: Added public method to retrieve the current PDF file path. Returns the most reliable path source (instance variable > state path).
- **Enhanced Path Extraction**: Improved `onLoadComplete` callback to receive file path directly from native module, ensuring more reliable path availability for bookmarking, export, and PDF operations.

### Fixed
- **Navigation Reliability**: Fixed issue where programmatic page navigation would not scroll to the target page. The native `setPage()` method now calls `jumpTo()` immediately when the page changes.
- **File Path Availability**: Fixed issue where `pdfFilePath` was sometimes empty in `onLoadComplete`, causing failures in export and PDF operations. Path is now reliably extracted from multiple sources with proper fallbacks.
- **Native Event Handling**: Enhanced `loadComplete` event message format to include file path, improving reliability of path extraction in JavaScript.

### Changed
- **Native Message Format**: Updated `loadComplete` event format from `loadComplete|pages|width|height|tableContents` to `loadComplete|pages|width|height|path|tableContents` for backward compatibility with automatic detection of old/new formats.
- **Path Tracking**: File paths are now stored in an instance variable (`downloadedFilePath`) immediately upon file preparation/download completion, in addition to React state, ensuring synchronous access.

## [3.3.0] - Previous Version

Previous release notes...

