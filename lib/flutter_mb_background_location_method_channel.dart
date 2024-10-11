import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_mb_background_location_platform_interface.dart';

/// An implementation of [FlutterMbBackgroundLocationPlatform] that uses method channels.
class MethodChannelFlutterMbBackgroundLocation extends FlutterMbBackgroundLocationPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_mb_background_location');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
