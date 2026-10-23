class AppSession {
  AppSession._();

  static String? _token;

  static void establish(String token) {
    if (token.isEmpty) {
      throw ArgumentError.value(token, 'token', 'No puede estar vacío.');
    }
    _token = token;
  }

  static void clear() {
    _token = null;
  }

  static Map<String, String> authHeaders({bool json = false}) {
    final token = _token;
    if (token == null) {
      throw StateError('Debes iniciar sesión para realizar esta acción.');
    }

    return {
      if (json) 'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }
}
