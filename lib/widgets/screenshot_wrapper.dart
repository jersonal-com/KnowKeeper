import 'package:flutter/material.dart';
import 'package:device_frame/device_frame.dart';

class ScreenshotWrapper extends StatelessWidget {
  final Widget child;
  final String message;
  final DeviceInfo device;

  const ScreenshotWrapper({
    super.key,
    required this.child,
    required this.message,
    required this.device,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey[200],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              message,
              style: Theme.of(context).textTheme.titleSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            DeviceFrame(
              device: device,
              screen: child,
            ),
          ],
        ),
      ),
    );
  }
}