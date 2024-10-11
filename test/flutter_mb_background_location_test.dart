import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterMbBackgroundLocationPlatform with MockPlatformInterfaceMixin {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  test('s the default instance', () {});

  test('getPlatformVersion', () async {});
}
