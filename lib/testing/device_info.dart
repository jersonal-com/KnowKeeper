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

  DeviceInfoData({
    required this.name,
    required this.device,
    required this.deviceFrameInfo,
    required this.orientation,
    this.appStoreDirectory,
  });
}

class DeviceInfoUtils {
  static final devices = [
    DeviceInfoData(
      name: 'phone_dummy',
      device: Device.phone,
      deviceFrameInfo: Devices.ios.iPhone13,
      orientation: Orientation.portrait,
    ),
    DeviceInfoData(
      name: 'phone',
      device: Device.phone,
      deviceFrameInfo: Devices.android.mediumPhone,
      orientation: Orientation.portrait,
      appStoreDirectory: 'phoneScreenshots',
    ),
    DeviceInfoData(
      name: 'iphone11',
      device: Device.iphone11,
      deviceFrameInfo: Devices.ios.iPhone13,
      orientation: Orientation.portrait,
    ),
    DeviceInfoData(
      name: 'iPadPro11Inches',
      device: Device.tabletLandscape,
      deviceFrameInfo: Devices.ios.iPadPro11Inches,
      orientation: Orientation.landscape,
    ),
    DeviceInfoData(
      name: 'mediumTablet',
      device: Device.tabletPortrait,
      deviceFrameInfo: Devices.android.mediumTablet,
      orientation: Orientation.portrait,
      appStoreDirectory: 'sevenInchScreenshots',
    ),
    DeviceInfoData(
      name: 'largeTablet',
      device: Device.tabletPortrait,
      deviceFrameInfo: Devices.android.largeTablet,
      orientation: Orientation.portrait,
      appStoreDirectory: 'tenInchScreenshots',
    ),
  ];

  static String createFileName(String scenarioName, DeviceInfoData deviceInfo, Locale locale, {bool framed = false, bool fromRoot = false}) {
    final orientationSuffix = deviceInfo.orientation == Orientation.landscape ? '_landscape' : '';
    final frameSuffix = framed ? '.framed' : '';
    final rootSuffix = fromRoot ? 'test/screenshots/' : '';
    final localeName = "${locale.languageCode}_${locale.countryCode}";
    return '${rootSuffix}goldens/${localeName}_${scenarioName}_${deviceInfo.name}$orientationSuffix$frameSuffix.png';
  }
}