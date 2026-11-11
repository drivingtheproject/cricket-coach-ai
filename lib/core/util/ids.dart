import 'dart:math';

final Random _random = Random.secure();

/// Random 128-bit identifier as 32 hex characters.
String newId() {
  final buffer = StringBuffer();
  for (var i = 0; i < 16; i++) {
    buffer.write(_random.nextInt(256).toRadixString(16).padLeft(2, '0'));
  }
  return buffer.toString();
}
