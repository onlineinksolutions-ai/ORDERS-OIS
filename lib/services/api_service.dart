import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Centralise tous les appels a l'API OIS.
/// Aucune cle secrete ici : seulement URL + token de session.
class ApiService {
  static const _kBaseUrl = 'api_base_url';
  static const _kToken = 'api_token';
  static const _kUser = 'api_user';

  static String _baseUrl = '';
  static String? _token;

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _baseUrl = p.getString(_kBaseUrl) ?? '';
    _token = p.getString(_kToken);
  }

  static bool get isLoggedIn => _token != null && _baseUrl.isNotEmpty;
  static String get baseUrl => _baseUrl;

  static String _normalize(String url) {
    var u = url.trim();
    if (u.endsWith('/')) u = u.substring(0, u.length - 1);
    return u;
  }

  static Uri _uri(String path, [Map<String, String>? q]) {
    return Uri.parse('$_baseUrl/$path').replace(queryParameters: q);
  }

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  /// Connexion. Stocke baseUrl + token si succes.
  static Future<bool> login(String url, String username, String password) async {
    final base = _normalize(url);
    final res = await http.post(
      Uri.parse('$base/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200 && data['success'] == true) {
      _baseUrl = base;
      _token = data['token'] as String;
      final p = await SharedPreferences.getInstance();
      await p.setString(_kBaseUrl, base);
      await p.setString(_kToken, _token!);
      await p.setString(_kUser, (data['user']?['name'] ?? '') as String);
      return true;
    }
    return false;
  }

  static Future<void> logout() async {
    _token = null;
    final p = await SharedPreferences.getInstance();
    await p.remove(_kToken);
  }

  static Future<Map<String, dynamic>> _get(String path,
      [Map<String, String>? q]) async {
    final res = await http.get(_uri(path, q), headers: _headers);
    if (res.statusCode == 401) {
      await logout();
      throw ApiException('Session expiree, reconnectez-vous.');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (data['success'] != true) {
      throw ApiException(data['error']?.toString() ?? 'Erreur API');
    }
    return data;
  }

  static Future<Map<String, dynamic>> stats() => _get('stats');

  static Future<Map<String, dynamic>> statuses() => _get('statuses');

  static Future<Map<String, dynamic>> orders({
    int page = 1,
    int limit = 20,
    String? search,
    String? dateFrom,
    String? dateTo,
    int? status,
    bool onlyNew = false,
    String? payment,
  }) {
    final q = <String, String>{'page': '$page', 'limit': '$limit'};
    if (search != null && search.isNotEmpty) q['search'] = search;
    if (dateFrom != null) q['date_from'] = dateFrom;
    if (dateTo != null) q['date_to'] = dateTo;
    if (status != null && status > 0) q['status'] = '$status';
    if (onlyNew) q['only_new'] = '1';
    if (payment != null && payment.isNotEmpty) q['payment'] = payment;
    return _get('orders', q);
  }

  static Future<Map<String, dynamic>> orderDetail(int id) => _get('orders/$id');

  static Future<Map<String, dynamic>> notificationsCheck(int sinceId) =>
      _get('notifications/check', {'since_id': '$sinceId'});

  static Future<bool> updateStatus(int id, int status) async {
    final res = await http.post(_uri('orders/$id/status'),
        headers: _headers, body: jsonEncode({'status': status}));
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return res.statusCode == 200 && data['success'] == true;
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}
