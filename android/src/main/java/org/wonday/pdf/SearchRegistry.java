/**
 * Registry mapping pdfId to current PDF file path for programmatic search.
 * PdfView registers when a document loads with pdfId; searchTextDirect looks up path by pdfId.
 * Also stores PDF page sizes in points (per pdfId + pageIndex) for highlight coordinate scaling.
 */
package org.wonday.pdf;

import java.util.concurrent.ConcurrentHashMap;

public final class SearchRegistry {
    private static final ConcurrentHashMap<String, String> pdfIdToPath = new ConcurrentHashMap<>();
    /** Key: pdfId + "_" + pageIndex0Based, value: float[2] = { widthPt, heightPt } */
    private static final ConcurrentHashMap<String, float[]> pdfIdPageSizePoints = new ConcurrentHashMap<>();

    public static void registerPath(String pdfId, String path) {
        if (pdfId != null && !pdfId.isEmpty() && path != null && !path.isEmpty()) {
            pdfIdToPath.put(pdfId, path);
        }
    }

    public static void unregisterPath(String pdfId) {
        if (pdfId != null && !pdfId.isEmpty()) {
            pdfIdToPath.remove(pdfId);
            // Clear page sizes for this pdfId
            pdfIdPageSizePoints.keySet().removeIf(k -> k != null && k.startsWith(pdfId + "_"));
        }
    }

    public static String getPath(String pdfId) {
        return pdfId == null ? null : pdfIdToPath.get(pdfId);
    }

    /** Register page size in PDF points (for highlight scaling). */
    public static void registerPageSizePoints(String pdfId, int pageIndex0Based, float widthPt, float heightPt) {
        if (pdfId != null && !pdfId.isEmpty() && widthPt > 0 && heightPt > 0) {
            pdfIdPageSizePoints.put(pdfId + "_" + pageIndex0Based, new float[] { widthPt, heightPt });
        }
    }

    /** Get page size in PDF points; returns float[2] = { widthPt, heightPt } or null. */
    public static float[] getPageSizePoints(String pdfId, int pageIndex0Based) {
        return pdfId == null ? null : pdfIdPageSizePoints.get(pdfId + "_" + pageIndex0Based);
    }
}
