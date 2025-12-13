/**
 * Copyright (c) 2025-present, Punith M (punithm300@gmail.com)
 * FileDownloader for iOS - Downloads files to Documents directory or iCloud Drive
 * All rights reserved.
 * 
 * Downloads files to public storage and shows notifications
 */

#import "FileDownloader.h"
#import <React/RCTLog.h>
#import <React/RCTUtils.h>
#import <UserNotifications/UserNotifications.h>
#import <UIKit/UIKit.h>

static NSString * const FOLDER_NAME = @"PDFDemoApp";
static NSString * const NOTIFICATION_IDENTIFIER = @"pdf_exports";

@implementation FileDownloader {
    NSURLSession *_downloadSession;
}

RCT_EXPORT_MODULE(FileDownloader);

+ (BOOL)requiresMainQueueSetup {
    return NO;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // Configure URL session for downloads
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.timeoutIntervalForRequest = 30.0;
        config.timeoutIntervalForResource = 60.0;
        _downloadSession = [NSURLSession sessionWithConfiguration:config];
        
        RCTLogInfo(@"📥 FileDownloader initialized for iOS");
    }
    return self;
}

- (NSArray<NSString *> *)supportedEvents {
    return @[@"FileDownloadProgress", @"FileDownloadComplete"];
}

/**
 * Request notification permissions (called when needed, not on init)
 */
- (void)requestNotificationPermissionsWithCompletion:(void (^)(BOOL granted))completion {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    
    // First check current authorization status
    [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
        if (settings.authorizationStatus == UNAuthorizationStatusAuthorized) {
            // Already authorized
            if (completion) {
                completion(YES);
            }
            return;
        }
        
        // Request authorization
        [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge)
                              completionHandler:^(BOOL granted, NSError * _Nullable error) {
            if (error) {
                RCTLogError(@"❌ Error requesting notification permissions: %@", error.localizedDescription);
            }
            
            if (granted) {
                RCTLogInfo(@"📱 [NOTIFICATION] Permission request: GRANTED");
            } else {
                RCTLogInfo(@"⚠️ [NOTIFICATION] Permission request: DENIED");
                if (error) {
                    RCTLogError(@"❌ [NOTIFICATION] Permission request error: %@", error.localizedDescription);
                }
            }
            
            if (completion) {
                completion(granted);
            }
        }];
    }];
}

/**
 * Download file to Documents/PDFDemoApp folder
 * @param sourcePath Path to source file in app's cache
 * @param fileName Name for the downloaded file
 * @param mimeType MIME type (application/pdf, image/png, image/jpeg)
 * @param promise Promise to resolve with public file path
 */
RCT_EXPORT_METHOD(downloadToPublicFolder:(NSString *)sourcePath
                  fileName:(NSString *)fileName
                  mimeType:(NSString *)mimeType
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        @try {
            RCTLogInfo(@"📥 [DOWNLOAD] START - file: %@, type: %@", fileName, mimeType);
            RCTLogInfo(@"📁 [SOURCE] %@", sourcePath);
            
            // Verify source file exists
            NSFileManager *fileManager = [NSFileManager defaultManager];
            if (![fileManager fileExistsAtPath:sourcePath]) {
                RCTLogError(@"❌ [ERROR] Source file not found: %@", sourcePath);
                reject(@"FILE_NOT_FOUND", @"Source file not found", nil);
                return;
            }
            
            NSDictionary *fileAttrs = [fileManager attributesOfItemAtPath:sourcePath error:nil];
            unsigned long long fileSize = [fileAttrs fileSize];
            RCTLogInfo(@"📁 [SOURCE] File exists, size: %llu bytes", fileSize);
            
            // Get Documents directory
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsDirectory = [paths firstObject];
            NSString *appFolder = [documentsDirectory stringByAppendingPathComponent:FOLDER_NAME];
            
            // Create folder if needed
            NSError *error;
            if (![fileManager fileExistsAtPath:appFolder]) {
                BOOL created = [fileManager createDirectoryAtPath:appFolder
                                      withIntermediateDirectories:YES
                                                       attributes:nil
                                                            error:&error];
                if (!created) {
                    RCTLogError(@"❌ [ERROR] Failed to create folder: %@", error.localizedDescription);
                    reject(@"FOLDER_CREATE_ERROR", @"Failed to create folder", error);
                    return;
                }
                RCTLogInfo(@"📁 [FOLDER] Created: %@", appFolder);
            }
            
            // Destination path
            NSString *destPath = [appFolder stringByAppendingPathComponent:fileName];
            
            // Remove existing file if it exists
            if ([fileManager fileExistsAtPath:destPath]) {
                NSError *removeError;
                BOOL removed = [fileManager removeItemAtPath:destPath error:&removeError];
                if (!removed) {
                    RCTLogError(@"❌ [ERROR] Failed to remove existing file: %@", removeError.localizedDescription);
                    reject(@"REMOVE_ERROR", @"Failed to remove existing file", removeError);
                    return;
                }
                RCTLogInfo(@"📁 [CLEANUP] Removed existing file: %@", fileName);
            }
            
            // Emit start event
            @try {
                [self sendEventWithName:@"FileDownloadProgress" body:@{
                    @"type": @"downloadStart",
                    @"fileName": fileName,
                    @"progress": @0.0
                }];
            } @catch (NSException *exception) {
                // Event emitter not ready, continue without event
            }
            
            // Copy file
            RCTLogInfo(@"📥 [COPY] Copying file...");
            
            // Emit progress event (for file copy, we can estimate)
            @try {
                [self sendEventWithName:@"FileDownloadProgress" body:@{
                    @"type": @"downloadProgress",
                    @"fileName": fileName,
                    @"progress": @0.5,
                    @"bytesDownloaded": @(fileSize / 2),
                    @"totalBytes": @(fileSize)
                }];
            } @catch (NSException *exception) {
                // Event emitter not ready, continue without event
            }
            
            BOOL success = [fileManager copyItemAtPath:sourcePath toPath:destPath error:&error];
            
            if (!success) {
                RCTLogError(@"❌ [ERROR] Failed to copy file: %@", error.localizedDescription);
                reject(@"COPY_ERROR", @"Failed to copy file", error);
                return;
            }
            
            RCTLogInfo(@"✅ [DOWNLOAD] SUCCESS - %@", destPath);
            
            // Emit complete event
            @try {
                [self sendEventWithName:@"FileDownloadComplete" body:@{
                    @"type": @"downloadComplete",
                    @"fileName": fileName,
                    @"path": destPath,
                    @"publicPath": destPath,
                    @"size": [NSString stringWithFormat:@"%llu", fileSize],
                    @"success": @YES
                }];
            } @catch (NSException *exception) {
                // Event emitter not ready, continue without event
            }
            
            // Show notification
            [self showDownloadNotification:fileName];
            
            resolve(destPath);
            
        } @catch (NSException *exception) {
            RCTLogError(@"❌ [DOWNLOAD] ERROR: %@", exception.reason);
            reject(@"DOWNLOAD_ERROR", exception.reason, nil);
        }
    });
}

/**
 * Download file from URL to Documents/PDFDemoApp folder
 * @param url URL to download from
 * @param fileName Name for the downloaded file
 * @param mimeType MIME type
 * @param promise Promise to resolve with downloaded file path
 */
RCT_EXPORT_METHOD(downloadFile:(NSString *)url
                  fileName:(NSString *)fileName
                  mimeType:(NSString *)mimeType
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        @try {
            RCTLogInfo(@"📥 [DOWNLOAD_URL] START - url: %@", url);
            
            // Validate URL
            if (!url || url.length == 0) {
                RCTLogError(@"❌ [DOWNLOAD_URL] Empty URL");
                reject(@"INVALID_URL", @"URL cannot be empty", nil);
                return;
            }
            
            // Check for special URL types
            if ([url isEqualToString:@"duplicate-current"]) {
                RCTLogError(@"❌ [DOWNLOAD_URL] Special URL type not handled here");
                reject(@"SPECIAL_URL", @"PDF duplication must be handled in React Native layer", nil);
                return;
            }
            
            if ([url isEqualToString:@"custom-url"]) {
                RCTLogError(@"❌ [DOWNLOAD_URL] Custom URL requires user input");
                reject(@"CUSTOM_URL_REQUIRED", @"Please provide a custom URL", nil);
                return;
            }
            
            // Validate HTTP/HTTPS URL
            if (![url hasPrefix:@"http://"] && ![url hasPrefix:@"https://"]) {
                RCTLogError(@"❌ [DOWNLOAD_URL] Invalid URL protocol: %@", url);
                reject(@"INVALID_PROTOCOL", @"URL must start with http:// or https://", nil);
                return;
            }
            
            // Create cache file first
            NSArray *cachePaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
            NSString *cacheDirectory = [cachePaths firstObject];
            NSString *cacheFilePath = [cacheDirectory stringByAppendingPathComponent:fileName];
            
            // Emit start event
            @try {
                [self sendEventWithName:@"FileDownloadProgress" body:@{
                    @"type": @"downloadStart",
                    @"fileName": fileName,
                    @"url": url,
                    @"progress": @0.0
                }];
            } @catch (NSException *exception) {
                // Event emitter not ready, continue without event
            }
            
            // Download from URL
            NSURL *downloadURL = [NSURL URLWithString:url];
            NSURLRequest *request = [NSURLRequest requestWithURL:downloadURL];
            
            NSURLSessionDownloadTask *downloadTask = [self->_downloadSession downloadTaskWithRequest:request
                                                                                    completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
                if (error) {
                    RCTLogError(@"❌ [DOWNLOAD_URL] Network error: %@", error.localizedDescription);
                    
                    // Emit error event
                    @try {
                        [self sendEventWithName:@"FileDownloadComplete" body:@{
                            @"type": @"downloadError",
                            @"fileName": fileName,
                            @"error": error.localizedDescription,
                            @"success": @NO
                        }];
                    } @catch (NSException *exception) {
                        // Event emitter not ready, continue without event
                    }
                    
                    reject(@"DOWNLOAD_ERROR", error.localizedDescription, error);
                    return;
                }
                
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                if (httpResponse.statusCode == 404) {
                    RCTLogError(@"❌ [DOWNLOAD_URL] HTTP 404 - File not found");
                    
                    // Emit error event
                    @try {
                        [self sendEventWithName:@"FileDownloadComplete" body:@{
                            @"type": @"downloadError",
                            @"fileName": fileName,
                            @"error": @"URL not accessible (404)",
                            @"success": @NO
                        }];
                    } @catch (NSException *exception) {
                        // Event emitter not ready, continue without event
                    }
                    
                    reject(@"FILE_NOT_FOUND", @"URL not accessible (404). The file may have been removed or the URL is incorrect.", nil);
                    return;
                } else if (httpResponse.statusCode == 403) {
                    RCTLogError(@"❌ [DOWNLOAD_URL] HTTP 403 - Access forbidden");
                    
                    // Emit error event
                    @try {
                        [self sendEventWithName:@"FileDownloadComplete" body:@{
                            @"type": @"downloadError",
                            @"fileName": fileName,
                            @"error": @"URL not accessible (403)",
                            @"success": @NO
                        }];
                    } @catch (NSException *exception) {
                        // Event emitter not ready, continue without event
                    }
                    
                    reject(@"ACCESS_FORBIDDEN", @"URL not accessible (403). The server is blocking access.", nil);
                    return;
                } else if (httpResponse.statusCode != 200) {
                    RCTLogError(@"❌ [DOWNLOAD_URL] HTTP error: %ld", (long)httpResponse.statusCode);
                    
                    // Emit error event
                    @try {
                        [self sendEventWithName:@"FileDownloadComplete" body:@{
                            @"type": @"downloadError",
                            @"fileName": fileName,
                            @"error": [NSString stringWithFormat:@"HTTP error %ld", (long)httpResponse.statusCode],
                            @"success": @NO
                        }];
                    } @catch (NSException *exception) {
                        // Event emitter not ready, continue without event
                    }
                    
                    reject(@"DOWNLOAD_FAILED", [NSString stringWithFormat:@"HTTP error %ld", (long)httpResponse.statusCode], nil);
                    return;
                }
                
                // Emit progress event when download starts
                long long expectedContentLength = httpResponse.expectedContentLength;
                if (expectedContentLength > 0) {
                    @try {
                        [self sendEventWithName:@"FileDownloadProgress" body:@{
                            @"type": @"downloadProgress",
                            @"fileName": fileName,
                            @"progress": @0.1,
                            @"bytesDownloaded": @(expectedContentLength / 10),
                            @"totalBytes": @(expectedContentLength)
                        }];
                    } @catch (NSException *exception) {
                        // Event emitter not ready, continue without event
                    }
                }
                
                // Move downloaded file to cache
                NSFileManager *fileManager = [NSFileManager defaultManager];
                NSError *moveError;
                if ([fileManager fileExistsAtPath:cacheFilePath]) {
                    [fileManager removeItemAtPath:cacheFilePath error:nil];
                }
                BOOL moved = [fileManager moveItemAtURL:location toURL:[NSURL fileURLWithPath:cacheFilePath] error:&moveError];
                
                if (!moved) {
                    RCTLogError(@"❌ [DOWNLOAD_URL] Failed to move file: %@", moveError.localizedDescription);
                    reject(@"MOVE_ERROR", @"Failed to move downloaded file", moveError);
                    return;
                }
                
                RCTLogInfo(@"✅ [DOWNLOAD_URL] Downloaded to cache: %@", cacheFilePath);
                
                // Get actual file size
                NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:cacheFilePath error:nil];
                unsigned long long fileSize = [fileAttributes fileSize];
                
                // Emit progress event (download complete, now copying)
                @try {
                    [self sendEventWithName:@"FileDownloadProgress" body:@{
                        @"type": @"downloadProgress",
                        @"fileName": fileName,
                        @"progress": @0.9,
                        @"bytesDownloaded": @(fileSize),
                        @"totalBytes": @(fileSize),
                        @"status": @"copying"
                    }];
                } @catch (NSException *exception) {
                    // Event emitter not ready, continue without event
                }
                
                // Now move to Documents/PDFDemoApp folder
                NSArray *documentsPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                NSString *documentsDirectory = [documentsPaths firstObject];
                NSString *appFolder = [documentsDirectory stringByAppendingPathComponent:FOLDER_NAME];
                
                // Create folder if needed
                if (![fileManager fileExistsAtPath:appFolder]) {
                    [fileManager createDirectoryAtPath:appFolder
                           withIntermediateDirectories:YES
                                            attributes:nil
                                                 error:nil];
                }
                
                NSString *publicPath = [appFolder stringByAppendingPathComponent:fileName];
                
                // Copy to public folder
                if ([fileManager fileExistsAtPath:publicPath]) {
                    [fileManager removeItemAtPath:publicPath error:nil];
                }
                
                BOOL copied = [fileManager copyItemAtPath:cacheFilePath toPath:publicPath error:&moveError];
                
                if (!copied) {
                    RCTLogError(@"❌ [DOWNLOAD_URL] Failed to copy to public folder: %@", moveError.localizedDescription);
                    reject(@"COPY_ERROR", @"Failed to copy to public folder", moveError);
                    return;
                }
                
                // Reuse fileSize from earlier (same file, just copied)
                NSDictionary *result = @{
                    @"path": cacheFilePath,
                    @"publicPath": publicPath,
                    @"size": [NSString stringWithFormat:@"%llu", fileSize]
                };
                
                // Emit complete event
                @try {
                    [self sendEventWithName:@"FileDownloadComplete" body:@{
                        @"type": @"downloadComplete",
                        @"fileName": fileName,
                        @"path": cacheFilePath,
                        @"publicPath": publicPath,
                        @"size": [NSString stringWithFormat:@"%llu", fileSize],
                        @"success": @YES
                    }];
                } @catch (NSException *exception) {
                    // Event emitter not ready, continue without event
                }
                
                RCTLogInfo(@"✅ [DOWNLOAD_URL] SUCCESS - Cache: %@, Public: %@", cacheFilePath, publicPath);
                resolve(result);
            }];
            
            [downloadTask resume];
            
        } @catch (NSException *exception) {
            RCTLogError(@"❌ [DOWNLOAD_URL] ERROR: %@", exception.reason);
            reject(@"DOWNLOAD_ERROR", exception.reason, nil);
        }
    });
}

/**
 * Show notification after successful download
 * Checks permissions before showing
 */
- (void)showDownloadNotification:(NSString *)fileName {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    
    RCTLogInfo(@"📱 [NOTIFICATION] Checking notification permissions for file: %@", fileName);
    
    // Check authorization status before showing notification
    [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
        NSString *statusString;
        switch (settings.authorizationStatus) {
            case UNAuthorizationStatusNotDetermined:
                statusString = @"Not Determined";
                break;
            case UNAuthorizationStatusDenied:
                statusString = @"Denied";
                break;
            case UNAuthorizationStatusAuthorized:
                statusString = @"Authorized";
                break;
            case UNAuthorizationStatusProvisional:
                statusString = @"Provisional";
                break;
            case UNAuthorizationStatusEphemeral:
                statusString = @"Ephemeral";
                break;
            default:
                statusString = @"Unknown";
                break;
        }
        RCTLogInfo(@"📱 [NOTIFICATION] Current authorization status: %@", statusString);
        
        if (settings.authorizationStatus != UNAuthorizationStatusAuthorized) {
            RCTLogInfo(@"📱 [NOTIFICATION] Permissions not authorized, requesting...");
            // Request permissions if not authorized
            [self requestNotificationPermissionsWithCompletion:^(BOOL granted) {
                if (granted) {
                    RCTLogInfo(@"📱 [NOTIFICATION] Permissions granted, displaying notification");
                    [self displayNotification:fileName];
                } else {
                    RCTLogInfo(@"⚠️ [NOTIFICATION] Cannot show notification - permissions denied by user");
                }
            }];
        } else {
            RCTLogInfo(@"📱 [NOTIFICATION] Permissions already authorized, displaying notification");
            // Already authorized, show notification
            [self displayNotification:fileName];
        }
    }];
}

/**
 * Display the notification (assumes permissions are granted)
 */
- (void)displayNotification:(NSString *)fileName {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.title = @"✅ Export Complete";
    content.body = [NSString stringWithFormat:@"1 file(s) saved to Documents/%@", FOLDER_NAME];
    content.sound = [UNNotificationSound defaultSound];
    content.badge = @1;
    
    // Add action to open Files app
    UNNotificationAction *openAction = [UNNotificationAction actionWithIdentifier:@"OPEN_FILES"
                                                                             title:@"Open Folder"
                                                                           options:UNNotificationActionOptionForeground];
    UNNotificationCategory *category = [UNNotificationCategory categoryWithIdentifier:NOTIFICATION_IDENTIFIER
                                                                              actions:@[openAction]
                                                                    intentIdentifiers:@[]
                                                                              options:UNNotificationCategoryOptionNone];
    
    [center setNotificationCategories:[NSSet setWithObject:category]];
    content.categoryIdentifier = NOTIFICATION_IDENTIFIER;
    
    UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1 repeats:NO];
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:[NSString stringWithFormat:@"download_%@", fileName]
                                                                          content:content
                                                                          trigger:trigger];
    
    RCTLogInfo(@"📱 [NOTIFICATION] Scheduling notification with identifier: %@", request.identifier);
    RCTLogInfo(@"📱 [NOTIFICATION] Notification content - Title: %@, Body: %@", content.title, content.body);
    
    [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
        if (error) {
            RCTLogError(@"❌ [NOTIFICATION] Failed to show notification: %@", error.localizedDescription);
            RCTLogError(@"❌ [NOTIFICATION] Error domain: %@, code: %ld", error.domain, (long)error.code);
        } else {
            RCTLogInfo(@"✅ [NOTIFICATION] Notification scheduled successfully with identifier: %@", request.identifier);
            RCTLogInfo(@"📱 [NOTIFICATION] Notification should appear in notification center");
        }
    }];
}

- (void)dealloc {
    [_downloadSession invalidateAndCancel];
    RCTLogInfo(@"📥 FileDownloader deallocated");
}

@end

