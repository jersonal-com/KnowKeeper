// lib/utils/device_info.dart
import 'package:device_frame/device_frame.dart';
import 'package:flutter/material.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

class DeviceInfoData {
  final String name;
  final Device device;
  final DeviceInfo deviceFrameInfo;
  final Orientation orientation;
  final String? appStoreDirectory;
  final Size? deviceSize;
  final double? density;

  DeviceInfoData({
    required this.name,
    required this.device,
    required this.deviceFrameInfo,
    required this.orientation,
    this.appStoreDirectory,
    this.deviceSize,
    this.density,
  });

  Size get size => (deviceSize != null) ? deviceSize! : device.size;

  double get devicePixelRatio =>
      (density != null) ? density! : device.devicePixelRatio;
}

class DeviceInfoUtils {
  static final devices = [
    DeviceInfoData(
      name: 'phone_dummy',
      device: Device.phone,
      deviceFrameInfo: Devices.ios.iPhone13,
      orientation: Orientation.portrait,
      deviceSize: const Size(1107, 1968),
      density: 3,
    ),
    DeviceInfoData(
      name: 'phone',
      device: Device.phone,
      deviceFrameInfo: Devices.android.mediumPhone,
      orientation: Orientation.portrait,
      appStoreDirectory: 'phoneScreenshots',
      deviceSize: const Size(1107, 1968),
      density: 3,
    ),
    DeviceInfoData(
      name: 'iphone11',
      device: Device.iphone11,
      deviceFrameInfo: Devices.ios.iPhone13,
      orientation: Orientation.portrait,
      deviceSize: const Size(1206, 2144),
      density: 2,
    ),
    DeviceInfoData(
      name: 'mediumTablet',
      device: Device.tabletPortrait,
      deviceFrameInfo: Devices.android.mediumTablet,
      orientation: Orientation.portrait,
      appStoreDirectory: 'sevenInchScreenshots',
      deviceSize: const Size(1206, 2144),
      density: 2,
    ),
    DeviceInfoData(
      name: 'iPadPro11Inches',
      device: Device.tabletLandscape,
      deviceFrameInfo: Devices.ios.iPadPro11Inches,
      orientation: Orientation.landscape,
      deviceSize: const Size(1449, 2576),
      density: 2,
    ),
    DeviceInfoData(
      name: 'largeTablet',
      device: Device.tabletPortrait,
      deviceFrameInfo: Devices.android.largeTablet,
      orientation: Orientation.portrait,
      appStoreDirectory: 'tenInchScreenshots',
      deviceSize: const Size(1449, 2576),
      density: 2,
    ),
  ];

  static String createFileName(
      String scenarioName, DeviceInfoData deviceInfo, Locale locale,
      {bool framed = false, bool fromRoot = false}) {
    final orientationSuffix =
        deviceInfo.orientation == Orientation.landscape ? '_landscape' : '';
    final frameSuffix = framed ? '.framed' : '';
    final rootSuffix = fromRoot ? 'test/screenshots/' : '';
    final localeName = "${locale.languageCode}_${locale.countryCode}";
    return '${rootSuffix}goldens/${localeName}_${scenarioName}_${deviceInfo.name}$orientationSuffix$frameSuffix.png';
  }
}
