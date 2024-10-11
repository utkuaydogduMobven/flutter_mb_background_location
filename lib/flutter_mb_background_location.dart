
import 'flutter_mb_background_location_platform_interface.dart';

class FlutterMbBackgroundLocation {
  Future<String?> getPlatformVersion() {
    return FlutterMbBackgroundLocationPlatform.instance.getPlatformVersion();
  }
}
