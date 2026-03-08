/**
 * Registry mapping pdfId to current PDF file path for programmatic search.
 * RNPDFPdfView registers when a document loads with pdfId; searchTextDirect looks up path by pdfId.
 * Also stores PDF page sizes in points (per pdfId + pageIndex) for highlight coordinate scaling.
 */
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SearchRegistry : NSObject

+ (void)registerPath:(NSString *)pdfId path:(NSString *)path;
+ (void)unregisterPath:(NSString *)pdfId;
+ (nullable NSString *)pathForPdfId:(NSString *)pdfId;

+ (void)registerPageSizePointsForPdfId:(NSString *)pdfId pageIndex0Based:(NSInteger)pageIndex widthPt:(CGFloat)widthPt heightPt:(CGFloat)heightPt;
+ (void)getPageSizePointsForPdfId:(NSString *)pdfId pageIndex0Based:(NSInteger)pageIndex widthOut:(CGFloat *)widthOut heightOut:(CGFloat *)heightOut;

@end

NS_ASSUME_NONNULL_END
