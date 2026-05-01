import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

class QrGenerator {
  QrGenerator._();

  static const _uuid = Uuid();
  static const _secret = 'switchen_qr_secret_2024';

  /// Generate a signed QR token for a given orderId
  static String generateToken(String orderId) {
    final nonce = _uuid.v4();
    final payload = '$orderId:$nonce';
    final signature = _sign(payload);
    return base64Url.encode(utf8.encode('$payload:$signature'));
  }

  /// Verify a QR token and return orderId if valid, null if tampered
  static String? verifyToken(String token) {
    try {
      final decoded = utf8.decode(base64Url.decode(token));
      final parts = decoded.split(':');
      if (parts.length < 3) return null;
      final orderId = parts[0];
      final nonce = parts[1];
      final signature = parts[2];
      final expectedSig = _sign('$orderId:$nonce');
      if (signature == expectedSig) return orderId;
      return null;
    } catch (_) {
      return null;
    }
  }

  static String _sign(String payload) {
    final key = utf8.encode(_secret);
    final bytes = utf8.encode(payload);
    final hmac = Hmac(sha256, key);
    return hmac.convert(bytes).toString().substring(0, 16);
  }
}
