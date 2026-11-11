import 'package:cricket_coach_ai/core/util/formatters.dart';
import 'package:cricket_coach_ai/core/util/ids.dart';
import 'package:cricket_coach_ai/core/util/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validateEmail', () {
    test('accepts a normal address, ignoring surrounding spaces', () {
      expect(validateEmail('  player@club.org '), isNull);
    });

    test('rejects empty and malformed addresses', () {
      expect(validateEmail(''), 'Enter your email address.');
      expect(validateEmail(null), 'Enter your email address.');
      expect(validateEmail('player@club'), 'Enter a valid email address.');
      expect(validateEmail('player club@x.org'), 'Enter a valid email address.');
    });
  });

  group('validateNewPassword', () {
    test('requires at least 8 characters', () {
      expect(validateNewPassword(''), 'Choose a password.');
      expect(validateNewPassword('1234567'), 'Use at least 8 characters.');
      expect(validateNewPassword('12345678'), isNull);
    });
  });

  group('validateDisplayName', () {
    test('requires a name of sensible length', () {
      expect(validateDisplayName('   '), 'Enter your name.');
      expect(validateDisplayName('A' * 41), 'Use 40 characters or fewer.');
      expect(validateDisplayName('Saurabh'), isNull);
    });
  });

  group('formatters', () {
    test('formatDate', () {
      expect(formatDate(DateTime(2026, 11, 11)), '11 Nov 2026');
      expect(formatDate(DateTime(2027, 1, 5)), '5 Jan 2027');
    });

    test('formatTime pads hours and minutes', () {
      expect(formatTime(DateTime(2026, 1, 1, 9, 5)), '09:05');
    });

    test('formatDuration rounds to whole seconds', () {
      expect(formatDuration(6200), '0:06');
      expect(formatDuration(75000), '1:15');
      expect(formatDuration(0), '0:00');
    });
  });

  group('newId', () {
    test('returns 32 hex characters and does not repeat', () {
      final ids = {for (var i = 0; i < 200; i++) newId()};
      expect(ids, hasLength(200));
      expect(ids.every(RegExp(r'^[0-9a-f]{32}$').hasMatch), isTrue);
    });
  });
}
