import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vani/services/backend_config.dart';

void main() {
  group('BackendConfig.resolveWebsocketUrl', () {
    test('keeps web URLs unchanged on web', () {
      final resolved = BackendConfig.resolveWebsocketUrl(
        'ws://localhost:8000/ws',
        isWeb: true,
        platform: TargetPlatform.android,
      );

      expect(resolved, 'ws://localhost:8000/ws');
    });

    test('rewrites localhost for Android emulators', () {
      final resolved = BackendConfig.resolveWebsocketUrl(
        'ws://localhost:8000/ws',
        isWeb: false,
        platform: TargetPlatform.android,
      );

      expect(resolved, 'ws://10.0.2.2:8000/ws');
    });

    test('preserves production host for non-Android targets', () {
      final resolved = BackendConfig.resolveWebsocketUrl(
        'wss://example.com/ws',
        isWeb: false,
        platform: TargetPlatform.iOS,
      );

      expect(resolved, 'wss://example.com/ws');
    });
  });
}