import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';

/// PBKDF2-HMAC-SHA256 password hashing.
///
/// Passwords are never stored in plain text. The stored format is
/// `salt:hash` where both sides are hex-encoded. A fixed iteration count is
/// used so that verification can reproduce the derived key from the stored
/// salt. Legacy plain-text hashes (no `:` separator) are still recognized so
/// existing accounts keep working after the migration.
class PasswordHasher {
  PasswordHasher._();

  static const int _iterations = 60_000;
  static const int _saltLength = 16;
  static const int _keyLength = 32;

  /// Hashes a plain-text password into a storable `salt:hash` string.
  static String hashPassword(String password) {
    final salt = _secureRandom(_saltLength);
    final key = _pbkdf2(utf8.encode(password), salt);
    return '${hex.encode(salt)}:${hex.encode(key)}';
  }

  /// Verifies a plain-text password against a stored hash.
  ///
  /// Returns `true` when the password matches. Legacy plain-text values are
  /// compared directly so previously registered accounts remain usable.
  static bool verifyPassword(String password, String? stored) {
    if (stored == null || stored.isEmpty) return false;
    if (!stored.contains(':')) {
      return password == stored;
    }
    final parts = stored.split(':');
    if (parts.length != 2) return false;
    late final List<int> salt;
    late final List<int> storedKey;
    try {
      salt = hex.decode(parts[0]);
      storedKey = hex.decode(parts[1]);
    } on FormatException {
      return false;
    }
    final computed = _pbkdf2(utf8.encode(password), salt);
    return _secureEquals(computed, storedKey);
  }

  static List<int> _pbkdf2(List<int> password, List<int> salt) {
    final hmac = Hmac(sha256, password);
    final blockSize = 64; // SHA-256 block size
    final blockCount = (_keyLength / blockSize).ceil();
    final out = <int>[];
    for (int block = 1; block <= blockCount; block++) {
      final blockIndex = _uint32BigEndian(block);
      var u = hmac.convert([...salt, ...blockIndex]).bytes;
      final acc = Uint8List.fromList(u);
      for (int i = 1; i < _iterations; i++) {
        u = hmac.convert(u).bytes;
        for (int k = 0; k < u.length; k++) {
          acc[k] ^= u[k];
        }
      }
      out.addAll(acc);
    }
    return out.sublist(0, _keyLength);
  }

  static List<int> _secureRandom(int length) {
    // math:Random is sufficient for a salt stored alongside a key-derived hash.
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }

  static List<int> _uint32BigEndian(int value) {
    return [
      (value >> 24) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 8) & 0xFF,
      value & 0xFF,
    ];
  }

  static bool _secureEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (int i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
