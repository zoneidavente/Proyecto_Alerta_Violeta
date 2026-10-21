const String _apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://proyecto-alerta-violeta.onrender.com',
);

Uri apiUri(String path) {
  final normalizedPath = path.startsWith('/') ? path : '/$path';
  return Uri.parse('$_apiBaseUrl$normalizedPath');
}