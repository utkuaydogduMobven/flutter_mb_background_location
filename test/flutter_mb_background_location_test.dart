import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mb_background_location/flutter_mb_background_location_platform_interface.dart';
import 'package:flutter_mb_background_location/flutter_mb_background_location_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterMbBackgroundLocationPlatform
    with MockPlatformInterfaceMixin
    implements FlutterMbBackgroundLocationPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlutterMbBackgroundLocationPlatform initialPlatform =
      FlutterMbBackgroundLocationPlatform.instance;

  test('$MethodChannelFlutterMbBackgroundLocation is the default instance', () {
    expect(initialPlatform,
        isInstanceOf<MethodChannelFlutterMbBackgroundLocation>());
  });

  test('getPlatformVersion', () async {});
}
