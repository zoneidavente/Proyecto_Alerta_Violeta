import 'package:flutter_test/flutter_test.dart';
import 'package:login_app/notification_service.dart';

void main() {
  group('isWithinNotificationWindow', () {
    final now = DateTime.utc(2026, 10, 23, 15);

    test('includes notifications from today and yesterday in Colombia', () {
      expect(
        isWithinNotificationWindow({
          'fecha': '2026-10-22T05:00:00.000Z',
          'categoria': 'Reporte',
        }, now: now),
        isTrue,
      );
      expect(
        isWithinNotificationWindow({
          'fecha': '2026-10-23T14:59:00.000Z',
          'categoria': 'SOS',
        }, now: now),
        isTrue,
      );
    });

    test('excludes notifications older than yesterday and future dates', () {
      expect(
        isWithinNotificationWindow({
          'fecha': '2026-10-22T04:59:59.999Z',
          'categoria': 'Reporte',
        }, now: now),
        isFalse,
      );
      expect(
        isWithinNotificationWindow({
          'fecha': '2026-10-23T15:00:00.001Z',
          'categoria': 'SOS',
        }, now: now),
        isFalse,
      );
    });

    test('excludes records without a valid date', () {
      expect(
        isWithinNotificationWindow({'categoria': 'SOS'}, now: now),
        isFalse,
      );
      expect(
        isWithinNotificationWindow({'fecha': 'invalid'}, now: now),
        isFalse,
      );
    });
  });
}
