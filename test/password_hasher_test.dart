import 'dart:convert';

import 'package:cricket_coach_ai/core/auth/password_hasher.dart';
import 'package:flutter_test/flutter_test.dart';

String hex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

String derive(String password, String salt, int iterations, int length) => hex(
      PasswordHasher.pbkdf2(
        utf8.encode(password),
        utf8.encode(salt),
        iterations,
        length,
      ),
    );

void main() {
  const hasher = PasswordHasher(iterations: 50);

  group('pbkdf2', () {
    test('matches published PBKDF2-HMAC-SHA256 vectors', () {
      expect(
        derive('password', 'salt', 1, 32),
        '120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b',
      );
      expect(
        derive('password', 'salt', 2, 32),
        'ae4d0c95af6b46d32d0adff928f06dd02a303f8ef3c251dfd6e2d85a95474c43',
      );
      expect(
        derive('password', 'salt', 4096, 32),
        'c5e478d59288c841aa530db6845c4c8d962893a001ce4e11a4963873aa98134a',
      );
    });

    test('derives keys longer than one hash block', () {
      expect(
        derive(
          'passwordPASSWORDpassword',
          'saltSALTsaltSALTsaltSALTsaltSALTsalt',
          4096,
          40,
        ),
        '348c89dbcbd32b2f32d814b8116e84cf2b17347ebc1800181c4e2a1fb8dd53e1'
        'c635518c7dac47e9',
      );
    });
  });

  group('PasswordHasher', () {
    test('verifies the right password and rejects a wrong one', () {
      final encoded = hasher.hash('correct horse');
      expect(hasher.verify('correct horse', encoded), isTrue);
      expect(hasher.verify('correct horsf', encoded), isFalse);
    });

    test('encodes scheme, iterations, salt and key', () {
      final parts = hasher.hash('secret-pass').split(r'$');
      expect(parts, hasLength(4));
      expect(parts[0], 'pbkdf2_sha256');
      expect(parts[1], '50');
      expect(base64Decode(parts[2]), hasLength(16));
      expect(base64Decode(parts[3]), hasLength(32));
    });

    test('uses a fresh salt each time', () {
      expect(hasher.hash('same'), isNot(hasher.hash('same')));
    });

    test('verifies hashes made with a different iteration count', () {
      final old = const PasswordHasher(iterations: 20).hash('legacy-pass');
      expect(hasher.verify('legacy-pass', old), isTrue);
    });

    test('rejects malformed stored values instead of throwing', () {
      expect(hasher.verify('x', ''), isFalse);
      expect(hasher.verify('x', 'plain-text-password'), isFalse);
      expect(hasher.verify('x', r'pbkdf2_sha256$abc$AAAA$AAAA'), isFalse);
      expect(hasher.verify('x', r'md5$10$AAAA$AAAA'), isFalse);
      expect(hasher.verify('x', r'pbkdf2_sha256$10$!!$AAAA'), isFalse);
    });
  });
}
