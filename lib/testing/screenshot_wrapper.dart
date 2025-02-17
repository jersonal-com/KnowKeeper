import 'package:flutter/material.dart';
import 'package:device_frame/device_frame.dart';

class ScreenshotWrapper extends StatelessWidget {
  final Widget child;
  final String message;
  final DeviceInfo device;
  final Orientation orientation;

  const ScreenshotWrapper({
    super.key,
    required this.child,
    required this.message,
    required this.device,
    this.orientation = Orientation.portrait,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xfff9a364),
            Color(0xFFf3877a),
          ],
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              DeviceFrame(
                device: device,
                screen: child,
                orientation: orientation,
              ),
            ],
          ),
        ),
      ),
    );
  }
}