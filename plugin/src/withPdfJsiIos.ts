import { ConfigPlugin, withXcodeProject } from '@expo/config-plugins';

/**
 * iOS config plugin for react-native-pdf-jsi
 * 
 * Configures the iOS project to support the PDF library:
 * - Ensures PDFKit framework is properly linked (handled automatically by CocoaPods)
 * 
 * Note: Most iOS configuration is handled by the podspec file.
 * This plugin exists for any additional Xcode project modifications if needed.
 */
export const withPdfJsiIos: ConfigPlugin = (config) => {
  return withXcodeProject(config, async (config) => {
    const xcodeProject = config.modResults;
    
    // PDFKit framework is automatically linked through the podspec's s.framework = "PDFKit"
    // This plugin hook is here for any future iOS-specific configurations
    
    // Ensure the project has the PDFKit framework if needed
    // (This is typically handled by CocoaPods, but we can add it explicitly if necessary)
    const frameworks = xcodeProject.pbxFrameworksBuildPhaseObj(
      xcodeProject.getFirstTarget().uuid
    );
    
    if (frameworks) {
      // Check if PDFKit is already linked
      const pdfKitLinked = Object.values(frameworks.files || {}).some(
        (file: any) => file?.comment?.includes('PDFKit')
      );
      
      if (!pdfKitLinked) {
        // PDFKit is a system framework, it will be linked via the podspec
        // No manual linking required in most cases
        console.log('[react-native-pdf-jsi] iOS: PDFKit will be linked via CocoaPods');
      }
    }
    
    return config;
  });
};
