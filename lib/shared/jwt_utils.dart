import 'dart:convert';

/// Decode JWT payload and return as Map, or null jika gagal.
Map<String, dynamic>? decodeJwtPayload(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;

    String payload = parts[1];
    String normalized = payload.replaceAll('-', '+').replaceAll('_', '/');
    switch (normalized.length % 4) {
      case 2:
        normalized += '==';
        break;
      case 3:
        normalized += '=';
        break;
    }

    final decoded = utf8.decode(base64Url.decode(normalized));
    final Map<String, dynamic> data = jsonDecode(decoded);
    return data;
  } catch (_) {
    return null;
  }
}

String? getBranchIdFromToken(String token) {
  final payload = decodeJwtPayload(token);
  return payload == null ? null : payload['branch_id']?.toString();
}

String? getNameFromToken(String token) {
  final payload = decodeJwtPayload(token);
  return payload == null ? null : payload['name']?.toString();
}

String? getUserRoleFromToken(String token) {
  final payload = decodeJwtPayload(token);
  return payload == null ? null : payload['user_role']?.toString();
}

/// Mengembalikan waktu expiry (`exp`) dalam bentuk DateTime UTC jika tersedia,
/// atau null kalau tidak ada atau tidak bisa di-parse.
DateTime? getExpiryFromToken(String token) {
  final payload = decodeJwtPayload(token);
  if (payload == null) return null;

  final exp = payload['exp'];
  if (exp == null) return null;

  try {
    // exp biasanya berupa int (seconds since epoch)
    if (exp is int) {
      return DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
    }
    if (exp is String) {
      final asInt = int.tryParse(exp);
      if (asInt != null) {
        return DateTime.fromMillisecondsSinceEpoch(asInt * 1000, isUtc: true);
      }
    }
  } catch (_) {
    return null;
  }
  return null;
}

/// Mengembalikan true jika token sudah expired (berdasarkan `exp`), false jika
/// masih valid atau `exp` tidak tersedia.
bool isTokenExpired(String token) {
  final expiry = getExpiryFromToken(token);
  if (expiry == null) return false; // Jangan anggap expired kalau tidak ada exp
  return DateTime.now().toUtc().isAfter(expiry);
}
