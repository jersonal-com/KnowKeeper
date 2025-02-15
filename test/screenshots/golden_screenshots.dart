import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:know_keeper/main.dart';
import 'package:know_keeper/screens/main_page.dart';
import 'package:know_keeper/screens/detail_page.dart';
import 'package:know_keeper/screens/config_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../test_helper.dart';

void main() {
  HttpOverrides.global = MyHttpOverrides();

  setUpAll(() async {
    await loadAppFonts();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Generate screenshots', (tester) async {
    final devices = [
      Device.phone,
      Device.iphone11,
      Device.tabletPortrait,
      Device.tabletLandscape,
    ];

    final scenarios = [
      ('main_page', TestHelper.wrapWithProviders(const MainPage())),
      ('detail_page', TestHelper.wrapWithProviders( DetailPage(entry: TestHelper.mockDetailEntry,))),
      ('config_page', TestHelper.wrapWithProviders(const ConfigPage())),
    ];

    for (final device in devices) {
      for (final scenario in scenarios) {
        // Set the screen size to match the device
        tester.binding.window.physicalSizeTestValue = device.size;
        tester.binding.window.devicePixelRatioTestValue = device.devicePixelRatio;

        // Pump the widget
        await tester.pumpWidget(scenario.$2);

        // Allow for any animations to complete
        await tester.pumpAndSettle();

        // Capture the screenshot
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/know_keeper_${scenario.$1}_${device.name}.png'),
        );
      }
    }

    // Reset the screen size
    addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
    addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);
  });
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}