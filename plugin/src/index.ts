import { ConfigPlugin, createRunOncePlugin } from '@expo/config-plugins';
import { withPdfJsiAndroid } from './withPdfJsiAndroid';
import { withPdfJsiIos } from './withPdfJsiIos';

const pkg = require('../../package.json');

/**
 * Expo config plugin for react-native-pdf-jsi
 * 
 * This plugin configures the native projects for Expo development builds.
 * It handles:
 * - Android: Jitpack repository for AndroidPdfViewer, NDK configuration
 * - iOS: PDFKit framework linking
 * 
 * Note: This package requires development builds and won't work with Expo Go.
 */
const withPdfJsi: ConfigPlugin = (config) => {
  // Warn about peer dependencies
  console.log(
    '[react-native-pdf-jsi] Remember to install peer dependencies:\n' +
    '  - react-native-blob-util\n' +
    '  - @react-native-async-storage/async-storage'
  );

  config = withPdfJsiAndroid(config);
  config = withPdfJsiIos(config);
  
  return config;
};

export default createRunOncePlugin(withPdfJsi, pkg.name, pkg.version);
