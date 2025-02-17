// ignore_for_file: prefer_final_locals, avoid_redundant_argument_values

// This test is tagged as "screenshots" and will be run only when the
// user explicitly runs `flutter test --tag screenshots`
@Tags(['screenshots'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:know_keeper/testing/device_info.dart';
import 'package:know_keeper/testing/locales_info.dart';
import 'package:know_keeper/testing/scenario_info.dart';
import 'package:know_keeper/testing/screenshot_wrapper.dart';
import 'package:shared_preferences/shared_preferences.dart';


void main() {
  setUpAll(() async {
    await loadAppFonts();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Generate framed screenshots', (tester) async {
    for (final locale in LocalesInfo.locales) {
      for (final deviceInfo in DeviceInfoUtils.devices) {
        // Do not ask why this has to run twice - otherwise Image.asset does
        // not render...
        for (var i = 0; i < 2; i++) {
          for (final scenario in ScenarioUtils.scenarios) {
            final screenFilePath = DeviceInfoUtils.createFileName(
                scenario.name, deviceInfo, locale, fromRoot: true);

            tester.view.physicalSize = deviceInfo.size;
            tester.view.devicePixelRatio = 1.0; // deviceInfo.devicePixelRatio

            // ;

            print("Size: ${tester.view.physicalSize}");
            print("Pixel ratio: ${tester.view.devicePixelRatio}");

            await tester.pumpWidget(
              MaterialApp(
                home: ScreenshotWrapper(
                  device: deviceInfo.deviceFrameInfo,
                  message: scenario.message,
                  orientation: deviceInfo.orientation,
                  child: Image.asset(screenFilePath),
                ),
              ),
            );

            for (var j = 0; j < 50; j++) {
              await tester.pump();
            }

            await tester.pumpAndSettle();

            final framedFileName = DeviceInfoUtils.createFileName(
                scenario.name, deviceInfo, locale, framed: true);
            await expectLater(
              find.byType(ScreenshotWrapper),
              matchesGoldenFile(framedFileName),
            );
          }
        }
      }
    }

    // Reset the window size and pixel ratio
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

}
