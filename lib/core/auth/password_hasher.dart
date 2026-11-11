import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Salted PBKDF2-HMAC-SHA256 password hashing.
///
/// The encoded form is `pbkdf2_sha256$iterations$salt$key` (salt and key in
/// base64), so the iteration count can be raised later without breaking
/// existing accounts.
class PasswordHasher {
  const PasswordHasher({this.iterations = 120000});

  final int iterations;

  static const String _scheme = 'pbkdf2_sha256';
  static const int _keyLength = 32;
  static const int _saltLength = 16;

  String hash(String password, {List<int>? salt}) {
    final saltBytes = salt ?? _randomBytes(_saltLength);
    final key = pbkdf2(utf8.encode(password), saltBytes, iterations, _keyLength);
    return [
      _scheme,
      iterations,
      base64Encode(saltBytes),
      base64Encode(key),
    ].join(r'$');
  }

  bool verify(String password, String encoded) {
    final parts = encoded.split(r'$');
    if (parts.length != 4 || parts[0] != _scheme) return false;
    final rounds = int.tryParse(parts[1]);
    final salt = _tryDecode(parts[2]);
    final expected = _tryDecode(parts[3]);
    if (rounds == null || rounds <= 0 || salt == null || expected == null) {
      return false;
    }
    final actual = pbkdf2(utf8.encode(password), salt, rounds, expected.length);
    return _constantTimeEquals(actual, expected);
  }

  /// PBKDF2 with HMAC-SHA256 (RFC 8018).
  static Uint8List pbkdf2(
    List<int> password,
    List<int> salt,
    int iterations,
    int keyLength,
  ) {
    final hmac = Hmac(sha256, password);
    final output = BytesBuilder(copy: false);
    var blockNumber = 1;
    while (output.length < keyLength) {
      final index = Uint8List(4)
        ..buffer.asByteData().setUint32(0, blockNumber);
      var u = hmac.convert([...salt, ...index]).bytes;
      final block = Uint8List.fromList(u);
      for (var i = 1; i < iterations; i++) {
        u = hmac.convert(u).bytes;
        for (var j = 0; j < block.length; j++) {
          block[j] ^= u[j];
        }
      }
      output.add(block);
      blockNumber++;
    }
    return Uint8List.sublistView(output.takeBytes(), 0, keyLength);
  }

  static List<int> _randomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }

  static List<int>? _tryDecode(String value) {
    try {
      return base64Decode(value);
    } on FormatException {
      return null;
    }
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var difference = 0;
    for (var i = 0; i < a.length; i++) {
      difference |= a[i] ^ b[i];
    }
    return difference == 0;
  }
}
