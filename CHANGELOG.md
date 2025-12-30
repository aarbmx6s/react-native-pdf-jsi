# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [4.1.0] - 2025-12-30

### Fixed
- **Android onLoadComplete Callback**: Fixed critical issue where `onLoadComplete` prop was not firing on Android devices
  - **Note**: iOS was not affected by this issue. iOS uses a notification-based approach (`PDFViewDocumentChangedNotification`) which is inherently more reliable. This fix is Android-specific.
  - Added comprehensive error handling in `loadComplete()` to ensure events are always dispatched even if errors occur during page size retrieval, zoom operations, or table of contents serialization
  - Implemented delayed event dispatch using `Handler.post()` to ensure React component is mounted and ready before dispatching `loadComplete` event, fixing timing issues
  - Restored `drawPdf()` call in `onAfterUpdateTransaction()` to ensure PDF loads properly on initial mount
  - Added duplicate call prevention to avoid multiple `loadComplete` events
  - Added fallback dispatch mechanism in `drawPdf()` when skipping reload if PDF is already loaded but event wasn't dispatched
  - Enhanced logging for debugging event dispatch issues
  - Resets event tracking flags when PDF path changes to ensure `onLoadComplete` fires for new documents

### Technical Details
- **PdfView.java**: Added `loadCompleteDispatched` and `lastKnownPageCount` tracking flags, delayed dispatch mechanism, and comprehensive error handling
- **PdfManager.java**: Restored `drawPdf()` call in `onAfterUpdateTransaction()` method
- **RNPDFPdfView.mm (iOS)**: Updated `onDocumentChanged` to include file path in `loadComplete` message for consistency with Android format
- **index.js**: Added debug logging for event tracking in development mode

This fix resolves the regression similar to [react-native-pdf issue #899](https://github.com/wonday/react-native-pdf/issues/899) and ensures reliable `onLoadComplete` callback execution on Android. iOS implementation was also updated to include file path in the message format for consistency.

## [4.0.0] - 2025-12-13

### Added
- **iOS Pro Features Port**: Complete feature parity with Android - all pro features now available on iOS
  - File download and management (FileDownloader, FileManager)
  - PDF export operations (split, merge, extract, rotate, delete)
  - Export to images (PNG/JPEG)
  - PDF compression
  - Text extraction
- **iOS Performance Optimizations**:
  - ImagePool for efficient UIImage reuse and memory management
  - LazyMetadataLoader for deferred PDF metadata loading
  - MemoryMappedCache for zero-copy file access using mmap()
  - StreamingPDFProcessor for chunk-based processing of large files
- **Cross-Platform Compatibility**: Platform.OS checks for method signature differences (Android 3 args vs iOS 2 args for splitPDF)

### Fixed
- **TypeScript Definitions**: Fixed malformed comment blocks in `index.d.ts` that made functional props appear commented out
  - All props (spacing, password, renderActivityIndicator, enableAntialiasing, enablePaging, enableRTL, enableAnnotationRendering, enableDoubleTapZoom, fitPolicy) now properly documented
- **Android splitPDF**: Fixed argument count mismatch - Android requires 3 arguments (filePath, ranges, outputDir) while iOS requires 2 (filePath, ranges)
- **Promise Resolution**: Fixed EXC_BAD_ACCESS crashes by ensuring all promise callbacks execute on main thread
- **File Download**: Removed unstable native folder creation code, using react-native-blob-util for folder operations

### Changed
- **FileManager.js**: Removed subfolderName parameters, simplified to use react-native-blob-util for folder creation
- **ExportManager.js**: Removed folderName parameters, added Platform.OS compatibility checks
- **iOS FileDownloader**: Simplified implementation, removed subfolder creation logic
- **iOS FileManager**: Removed native createSubfolder method

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

