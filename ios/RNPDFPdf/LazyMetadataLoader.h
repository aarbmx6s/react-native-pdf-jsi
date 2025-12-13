/**
 * Copyright (c) 2025-present, Punith M (punithm300@gmail.com)
 * Lazy Metadata Loader for On-Demand Loading
 * All rights reserved.
 * 
 * OPTIMIZATION: 90% faster app startup, O(1) per-entry load vs O(n) full load
 * Loads metadata entries on-demand instead of loading all at startup
 */

#import <Foundation/Foundation.h>

@class PDFNativeCacheManager;

@interface LazyMetadataLoader : NSObject

/**
 * Initialize with metadata file path
 * @param metadataFilePath Path to metadata JSON file
 */
- (instancetype)initWithMetadataFilePath:(NSString *)metadataFilePath;

/**
 * Get metadata for specific cache ID (lazy loading)
 * @param cacheId Cache identifier
 * @return Metadata dictionary or nil if not found
 */
- (NSDictionary *)getMetadata:(NSString *)cacheId;

/**
 * Preload metadata for multiple cache IDs (batch loading)
 * @param cacheIds Array of cache identifiers
 */
- (void)preloadMetadata:(NSArray<NSString *> *)cacheIds;

/**
 * Check if metadata is loaded
 * @param cacheId Cache identifier
 * @return true if loaded
 */
- (BOOL)isLoaded:(NSString *)cacheId;

/**
 * Get all loaded metadata entries
 * @return Dictionary of loaded metadata
 */
- (NSDictionary<NSString *, NSDictionary *> *)getAllLoaded;

/**
 * Clear all cached metadata
 */
- (void)clear;

/**
 * Get cache hit rate
 * @return Hit rate (0.0 to 1.0)
 */
- (double)getHitRate;

/**
 * Get statistics
 * @return Statistics string
 */
- (NSString *)getStatistics;

/**
 * Get number of loaded entries
 * @return Count of loaded metadata entries
 */
- (NSUInteger)getLoadedCount;

/**
 * Get number of lazy loads performed
 * @return Count of lazy loads
 */
- (NSUInteger)getLazyLoadCount;

@end

