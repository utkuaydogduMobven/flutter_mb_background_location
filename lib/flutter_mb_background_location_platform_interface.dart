import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_mb_background_location_method_channel.dart';

abstract class FlutterMbBackgroundLocationPlatform extends PlatformInterface {
  /// Constructs a FlutterMbBackgroundLocationPlatform.
  FlutterMbBackgroundLocationPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterMbBackgroundLocationPlatform _instance = MethodChannelFlutterMbBackgroundLocation();

  /// The default instance of [FlutterMbBackgroundLocationPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterMbBackgroundLocation].
  static FlutterMbBackgroundLocationPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterMbBackgroundLocationPlatform] when
  /// they register themselves.
  static set instance(FlutterMbBackgroundLocationPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
