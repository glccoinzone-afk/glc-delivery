import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const kBase = 'https://glczone.in/delivery_boy_api';
const _store = FlutterSecureStorage();

class Api {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: kBase,
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 20),
    headers: {'Accept': 'application/json'},
    validateStatus: (s) => s != null && s < 500,
  ))
    ..interceptors.add(InterceptorsWrapper(onRequest: (o, h) async {
      final t = await _store.read(key: 'token');
      if (t != null) o.headers['Authorization'] = 'Bearer $t';
      h.next(o);
    }));

  static Future<bool> hasToken() async => (await _store.read(key: 'token')) != null;

  static Future<Map<String, dynamic>> login(String mobile, String password) async {
    final r = await _dio.post('/login',
        data: FormData.fromMap({'mobile': mobile, 'password': password, 'country_code': '+91'}));
    final d = Map<String, dynamic>.from(r.data);
    if (d['error'] == false && d['token'] != null) {
      await _store.write(key: 'token', value: d['token'].toString());
    }
    return d;
  }

  static Future<Map<String, dynamic>> orders() async {
    final r = await _dio.get('/get_orders', queryParameters: {'limit': 25, 'offset': 0});
    if (r.statusCode == 401) await logout();
    return Map<String, dynamic>.from(r.data);
  }

  static Future<void> logout() => _store.delete(key: 'token');
}
