# iOS Permissions Guide

## Overview
This document explains the permissions required and how they are handled in the iOS implementation.

## Required Permissions

### 1. Notification Permissions
**Status**: ✅ Properly Handled

**What it's used for**: 
- Showing download completion notifications in `FileDownloader`

**How it's handled**:
- Permissions are requested **on-demand** when a notification needs to be shown (not on module initialization)
- Permission status is checked before attempting to show notifications
- Graceful fallback if permissions are denied (logs warning, doesn't crash)
- Error handling included in permission request

**Info.plist Requirements**: 
- ❌ **No Info.plist entry required** - Local notifications don't require usage descriptions

**Code Location**: 
- `ios/RNPDFPdf/FileDownloader.m` - `requestNotificationPermissionsWithCompletion:` and `showDownloadNotification:`

### 2. File System Access
**Status**: ✅ No Special Permissions Required

**What it's used for**:
- Accessing app's Documents directory
- Creating folders in app's sandbox
- Copying files within app's container

**How it's handled**:
- Uses `NSDocumentDirectory` which is within the app's sandbox
- No special permissions needed - apps have full access to their own sandbox
- Uses `NSFileManager` for file operations

**Info.plist Requirements**: 
- ❌ **No Info.plist entry required** - Accessing app's own sandbox doesn't require permissions

**Code Location**: 
- `ios/RNPDFPdf/FileDownloader.m` - File operations
- `ios/RNPDFPdf/FileManager.m` - File operations

### 3. UIDocumentPickerViewController
**Status**: ✅ No Special Permissions Required

**What it's used for**:
- Opening Files app to show downloaded files
- Providing user access to exported files

**How it's handled**:
- Uses `UIDocumentPickerViewController` which doesn't require special permissions
- Multiple fallback strategies for maximum compatibility
- Handles cases where Files app might not be available

**Info.plist Requirements**: 
- ❌ **No Info.plist entry required** - `UIDocumentPickerViewController` doesn't need permissions

**Code Location**: 
- `ios/RNPDFPdf/FileManager.m` - `openDownloadsFolder:`

## Permission Request Flow

### Notification Permissions
```
1. User triggers download/export
2. FileDownloader.showDownloadNotification() is called
3. Check current authorization status
4. If not authorized → Request permissions
5. If authorized → Show notification
6. If denied → Log warning, continue without notification
```

### File Access
```
1. No permission request needed
2. Direct access to NSDocumentDirectory (app's sandbox)
3. Create folders/files as needed
4. No user interaction required
```

## Best Practices Implemented

1. ✅ **On-Demand Permission Requests**: Permissions are requested when needed, not on app startup
2. ✅ **Permission Status Checks**: Always check authorization status before using protected resources
3. ✅ **Graceful Degradation**: App continues to work even if permissions are denied
4. ✅ **Error Handling**: All permission requests include error handling
5. ✅ **No Info.plist Pollution**: Only request permissions that are actually needed

## Testing Checklist

- [ ] Test notification permission request flow
- [ ] Test notification display when permissions granted
- [ ] Test graceful handling when permissions denied
- [ ] Test file operations in Documents directory
- [ ] Test UIDocumentPickerViewController on different iOS versions
- [ ] Verify no crashes when permissions are denied

## Notes

- **No Info.plist modifications needed** - All permissions are handled programmatically
- **No external dependencies** - Uses only iOS system frameworks
- **Backward compatible** - Works on iOS 11.0+ with appropriate fallbacks

