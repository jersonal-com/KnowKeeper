
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:know_keeper/screens/main_page.dart';
import 'package:know_keeper/screens/detail_page.dart';
import 'package:know_keeper/screens/config_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../test_helper.dart';

void main() {

  setUpAll(() async {
    // HttpOverrides.global = null; //MyHttpOverrides();
    await loadAppFonts();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Generate screenshots', (tester) async {
    final devices = [
      Device.phone,
      Device.phone,
      Device.iphone11,
      Device.tabletPortrait,
      Device.tabletLandscape,
    ];

    final scenarios = [
      ('main_page', const MainPage()),
      ('detail_page', DetailPage(entry: TestHelper.mockDetailEntry)),
      ('config_page', const ConfigPage()),
    ];

    for (final device in devices) {
      for (final scenario in scenarios) {


            // Set the screen size to match the device
            tester.view.physicalSize = device.size;
            tester.view.devicePixelRatio = device.devicePixelRatio;


            // Pump the widget
            await tester.pumpWidget(TestHelper.wrapWithProviders(scenario.$2),
                duration: const Duration(seconds: 5));

            await tester.pumpAndSettle(const Duration(seconds: 15),
              EnginePhase.sendSemanticsUpdate, const Duration(seconds: 30),);

            // Capture the screenshot
            await expectLater(
              find.byType(MaterialApp),
              matchesGoldenFile(
                  'goldens/know_keeper_${scenario.$1}_${device.name}.png'),
            );

      }
    }

    // Reset the screen size
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}

