class TokenStorage {
  String? _token;

  String? get token => _token;
  bool get hasToken => _token != null;

  void setToken(String token) => _token = token;

  void clearToken() => _token = null;
}
