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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:know_keeper/testing/test_helper.dart';


void main() {
  setUpAll(() async {
    await loadAppFonts();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Generate raw screenshots', (tester) async {
    for (final locale in LocalesInfo.locales) {
      for (final deviceInfo in DeviceInfoUtils.devices) {
        // Do not ask why this has to run twice - otherwise Image.asset does
        // not render...
        for (var i = 0; i < 1; i++) {
          for (final scenario in ScenarioUtils.scenarios) {
            // Set the screen size to match the device
            tester.view.physicalSize = deviceInfo.size;
            tester.view.devicePixelRatio = deviceInfo.devicePixelRatio;

            // Pump the widget
            await tester.pumpWidget(
              TestHelper.wrapWithProviders(scenario.widget,
                  themeMode: scenario.themeMode ?? ThemeMode.light),
            );

            // Execute pre-screenshot action if defined
            if (scenario.preScreenshotAction != null) {
              await scenario.preScreenshotAction!(tester);
            }

            // Pump a few seconds
            for (var j = 0; j < 50; j++) {
              await tester.pump();
            }

            await tester.pumpAndSettle(const Duration(seconds: 15));

            // Capture the raw screenshot
            final fileName =
                DeviceInfoUtils.createFileName(scenario.name, deviceInfo, locale);
            await expectLater(
              find.byType(MaterialApp),
              matchesGoldenFile(fileName),
            );
          }
        }
      }
    }

    // Reset the screen size
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}
