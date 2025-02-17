// This test is tagged as "screenshots" and will be run only when the
// user explicitly runs `flutter test --tag screenshots`
@Tags(['screenshots'])
library;


import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:know_keeper/testing/device_info.dart';
import 'package:know_keeper/testing/locales_info.dart';
import 'package:know_keeper/testing/scenario_info.dart';

void main() {
  setUpAll(() async {});

  testWidgets('Cleaning up and moving files', (tester) async {

    const documentDirectory = 'screen_shots';
    const appStoreDirectory = 'android/fastlane/metadata/android';

    for (final locale in LocalesInfo.locales) {
      for (final deviceInfo in DeviceInfoUtils.devices) {
        for (final scenario in ScenarioUtils.scenarios) {
          final fileName = DeviceInfoUtils.createFileName(
              scenario.name, deviceInfo, locale,
              fromRoot: true, framed: false);
          final file = File(fileName);

          final framedFileName = DeviceInfoUtils.createFileName(
              scenario.name, deviceInfo, locale,
              fromRoot: true, framed: true);
          final framedFile = File(framedFileName);

          // We use these images for the screenshots in the docs
          if (deviceInfo.device == Device.iphone11) {
            if (scenario.documentScreenshot != null) {
              final newFileName =
                  '$documentDirectory/${scenario.documentScreenshot}.png';
              if (file.existsSync()) {
                final newFile = File(newFileName);
                if (newFile.existsSync()) {
                  newFile.deleteSync();
                }
                file.copySync(newFileName);
              }
            }
          }

          // Now come the images for the app store
          if (scenario.appStoreNumber != null) {
            if (deviceInfo.appStoreDirectory != null) {
              final lang = "${locale.languageCode}-${locale.countryCode}";
              final newFilename = "$appStoreDirectory/$lang/images/${deviceInfo.appStoreDirectory}/${scenario.appStoreNumber}_$lang.png";
              final newFile = File(newFilename);
              if (newFile.existsSync()) {
                newFile.deleteSync();
              }
              framedFile.copySync(newFilename);
            }
          }

          // Finally delete the file
          file.deleteSync();
          framedFile.deleteSync();

        }
      }
    }
  });
}
