// lib/utils/scenario_info.dart
import 'package:flutter/material.dart';
import 'package:know_keeper/screens/export_page.dart';
import 'package:know_keeper/screens/main_page.dart';
import 'package:know_keeper/screens/detail_page.dart';
import 'package:know_keeper/screens/config_page.dart';
import 'test_helper.dart';

// ignore: depend_on_referenced_packages
import 'package:flutter_test/flutter_test.dart';

class ScenarioData {
  final String name;
  final Widget widget;
  final String message;
  final String? documentScreenshot;
  final int? appStoreNumber;
  final ThemeMode? themeMode;
  final Future<void> Function(WidgetTester)? preScreenshotAction;

  ScenarioData({
    required this.name,
    required this.widget,
    required this.message,
    this.documentScreenshot,
    this.appStoreNumber,
    this.themeMode,
    this.preScreenshotAction,
  });
}

class ScenarioUtils {
  static final scenarios = [
    ScenarioData(
      name: 'main_page',
      widget: const MainPage(),
      message: 'All your news and RSS in one place',
      documentScreenshot: 'main_page',
      appStoreNumber: 1,
    ),
    ScenarioData(
      name: 'main_page_dark',
      widget: const MainPage(),
      message: 'Supports light and dark mode',
      appStoreNumber: 2,
      documentScreenshot: 'dark_page',
      themeMode: ThemeMode.dark,
    ),
    ScenarioData(
      name: 'config_page',
      widget: const ConfigPage(),
      message: 'Requires no cloud - just a mail address',
      documentScreenshot: 'configuration_page',
      appStoreNumber: 3,
    ),
    ScenarioData(
      name: 'detail_page',
      widget: DetailPage(entry: TestHelper.mockDetailEntry),
      message: 'Read articles offline',
      documentScreenshot: 'detail_page',
      appStoreNumber: 4,
    ),
    ScenarioData(
      name: 'main_menu',
      widget: const MainPage(),
      message: 'Tag, Filter and Organize',
      preScreenshotAction: (tester) async {
        // Open the drawer before taking the screenshot
        await tester.tap(find.byIcon(Icons.menu));
        await tester.pumpAndSettle();
      },
      appStoreNumber: 5,
      documentScreenshot: 'main_page_menu',
    ),
    ScenarioData(
        name: 'export',
        widget: const ExportPage(),
        message: "Export your highlights",
        documentScreenshot: 'export_screen',
        appStoreNumber: 6,
    ),
  ];
}
