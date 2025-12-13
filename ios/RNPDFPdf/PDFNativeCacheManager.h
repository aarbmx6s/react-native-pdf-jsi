/**
 * 🚀 Native PDF Cache Manager for iOS (Inside react-native-pdf Package)
 * High-performance PDF caching with persistent native implementation
 */

#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
#import <Foundation/Foundation.h>

@class LazyMetadataLoader;
@class MemoryMappedCache;
@class StreamingPDFProcessor;

@interface PDFNativeCacheManager : RCTEventEmitter <RCTBridgeModule>

@property (nonatomic, strong) NSString *cacheDir;
@property (nonatomic, strong) NSString *metadataFilePath;
@property (nonatomic, strong) NSMutableDictionary *cacheMetadata;
@property (nonatomic, strong) NSMutableDictionary *cacheStats;
@property (nonatomic, strong) NSObject *cacheLock;
@property (nonatomic, assign) BOOL metadataDirty;
@property (nonatomic, strong) dispatch_source_t metadataSaveTimer;
@property (nonatomic, strong) LazyMetadataLoader *lazyLoader;
@property (nonatomic, strong) MemoryMappedCache *memoryMappedCache;
@property (nonatomic, strong) StreamingPDFProcessor *streamingProcessor;

// Singleton instance for direct access
+ (instancetype)sharedInstance;

@end
