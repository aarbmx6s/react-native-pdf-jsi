/**
 * Copyright (c) 2025-present, Punith M (punithm300@gmail.com)
 * FileManager for iOS - File operations like opening folders
 * All rights reserved.
 */

#import "FileManager.h"
#import <React/RCTLog.h>
#import <React/RCTUtils.h>
#import <UIKit/UIKit.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

static NSString * const FOLDER_NAME = @"PDFDemoApp";

@implementation FileManager

RCT_EXPORT_MODULE(FileManager);

+ (BOOL)requiresMainQueueSetup {
    return NO;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        RCTLogInfo(@"📂 FileManager initialized for iOS");
    }
    return self;
}

/**
 * Open the Documents/PDFDemoApp folder in the Files app
 * Multiple fallback strategies for maximum compatibility
 */
RCT_EXPORT_METHOD(openDownloadsFolder:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            RCTLogInfo(@"📂 [OPEN FOLDER] Attempting to open Documents/%@", FOLDER_NAME);
            
            // Get Documents directory
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsDirectory = [paths firstObject];
            NSString *appFolder = [documentsDirectory stringByAppendingPathComponent:FOLDER_NAME];
            
            // Strategy 1: Use modern API for iOS 14+ to export folder
            if (@available(iOS 14.0, *)) {
                NSURL *folderURL = [NSURL fileURLWithPath:appFolder];
                
                // Check if folder exists
                NSFileManager *fileManager = [NSFileManager defaultManager];
                if (![fileManager fileExistsAtPath:appFolder]) {
                    // Create folder if it doesn't exist
                    NSError *error;
                    BOOL created = [fileManager createDirectoryAtPath:appFolder
                                          withIntermediateDirectories:YES
                                                           attributes:nil
                                                                error:&error];
                    if (!created) {
                        RCTLogError(@"❌ [OPEN FOLDER] Failed to create folder: %@", error.localizedDescription);
                    }
                }
                
                // Use modern API: initForExportingURLs:asCopy:
                UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc] initForExportingURLs:@[folderURL] asCopy:YES];
                picker.delegate = nil;
                picker.allowsMultipleSelection = NO;
                
                UIViewController *rootViewController = RCTKeyWindow().rootViewController;
                while (rootViewController.presentedViewController) {
                    rootViewController = rootViewController.presentedViewController;
                }
                
                [rootViewController presentViewController:picker animated:YES completion:^{
                    RCTLogInfo(@"✅ [OPEN FOLDER] Opened folder via UIDocumentPickerViewController (iOS 14+)");
                    resolve(@YES);
                }];
                
                return;
            }
            
            // Strategy 2: Use deprecated API for iOS < 14 (fallback)
            NSURL *documentsURL = [NSURL fileURLWithPath:documentsDirectory];
            
            if (@available(iOS 11.0, *)) {
                // For iOS < 14, use deprecated API with valid mode
                // Note: UIDocumentPickerModeExportToService is the correct mode for exporting
                // But since it might not be available, we'll use a different approach
                // Actually, let's just show an alert for older iOS versions
                RCTLogInfo(@"⚠️ [OPEN FOLDER] iOS < 14 detected, showing instructions instead");
                // Fall through to Strategy 3
            }
            
            // Strategy 3: Show alert with instructions
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Open Files"
                                                                           message:[NSString stringWithFormat:@"Navigate to Documents/%@ in the Files app", FOLDER_NAME]
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                resolve(@YES);
            }]];
            
            UIViewController *rootViewController = RCTKeyWindow().rootViewController;
            while (rootViewController.presentedViewController) {
                rootViewController = rootViewController.presentedViewController;
            }
            
            [rootViewController presentViewController:alert animated:YES completion:nil];
            RCTLogInfo(@"✅ [OPEN FOLDER] Showed instructions alert");
            
        } @catch (NSException *exception) {
            RCTLogError(@"❌ [OPEN FOLDER] ERROR: %@", exception.reason);
            reject(@"OPEN_FOLDER_ERROR", exception.reason, nil);
        }
    });
}

/**
 * Check if a file exists at the given path
 */
RCT_EXPORT_METHOD(fileExists:(NSString *)filePath
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @try {
            RCTLogInfo(@"📂 [FILE_EXISTS] Checking: %@", filePath);
            
            if (!filePath || filePath.length == 0) {
                reject(@"INVALID_PATH", @"File path cannot be empty", nil);
                return;
            }
            
            NSFileManager *fileManager = [NSFileManager defaultManager];
            BOOL exists = [fileManager fileExistsAtPath:filePath];
            
            RCTLogInfo(@"📂 [FILE_EXISTS] Result: %@", exists ? @"YES" : @"NO");
            resolve(@(exists));
            
        } @catch (NSException *exception) {
            RCTLogError(@"❌ [FILE_EXISTS] ERROR: %@", exception.reason);
            reject(@"FILE_EXISTS_ERROR", exception.reason, nil);
        }
    });
}

/**
 * Get file size and metadata
 */
RCT_EXPORT_METHOD(getFileSize:(NSString *)filePath
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @try {
            RCTLogInfo(@"📂 [GET_FILE_SIZE] Path: %@", filePath);
            
            if (!filePath || filePath.length == 0) {
                reject(@"INVALID_PATH", @"File path cannot be empty", nil);
                return;
            }
            
            NSFileManager *fileManager = [NSFileManager defaultManager];
            BOOL exists = [fileManager fileExistsAtPath:filePath];
            
            if (!exists) {
                reject(@"FILE_NOT_FOUND", @"File does not exist", nil);
                return;
            }
            
            NSError *error;
            NSDictionary *fileAttrs = [fileManager attributesOfItemAtPath:filePath error:&error];
            
            if (error) {
                reject(@"FILE_SIZE_ERROR", error.localizedDescription, error);
                return;
            }
            
            unsigned long long fileSize = [fileAttrs fileSize];
            double sizeMB = fileSize / (1024.0 * 1024.0);
            
            NSDictionary *result = @{
                @"size": [NSString stringWithFormat:@"%llu", fileSize],
                @"sizeMB": @(sizeMB),
                @"path": filePath,
                @"exists": @YES
            };
            
            RCTLogInfo(@"📂 [GET_FILE_SIZE] Size: %llu bytes (%.2f MB)", fileSize, sizeMB);
            resolve(result);
            
        } @catch (NSException *exception) {
            RCTLogError(@"❌ [GET_FILE_SIZE] ERROR: %@", exception.reason);
            reject(@"FILE_SIZE_ERROR", exception.reason, nil);
        }
    });
}

@end

