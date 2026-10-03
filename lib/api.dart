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

  static Map<String, dynamic> _m(dynamic d) => d is Map
      ? Map<String, dynamic>.from(d)
      : {'error': true, 'message': 'Server se galat jawab aaya'};

  static Future<bool> hasToken() async => (await _store.read(key: 'token')) != null;

  static Future<Map<String, dynamic>> login(String mobile, String password) async {
    final r = await _dio.post('/login',
        data: FormData.fromMap({'mobile': mobile, 'password': password, 'country_code': '91'}));
    final d = _m(r.data);
    if (d['error'] == false && d['token'] != null) {
      await _store.write(key: 'token', value: d['token'].toString());
    }
    return d;
  }

  static Future<Map<String, dynamic>> orders() async {
    final r = await _dio.get('/get_orders', queryParameters: {'limit': 25, 'offset': 0});
    if (r.statusCode == 401) await logout();
    return _m(r.data);
  }

  static Future<Map<String, dynamic>> updateStatus(int id, String status, {String? otp}) async {
    final r = await _dio.put('/update_order_item_status', data: {
      'id': id,
      'status': status,
      if (otp != null && otp.isNotEmpty) 'otp': otp,
    });
    if (r.statusCode == 401) await logout();
    return _m(r.data);
  }

  static Future<Map<String, dynamic>> respond(int parcelId, String action, {String? reason}) async {
    final r = await _dio.post('/respond_assignment', data: {
      'parcel_id': parcelId,
      'action': action,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    });
    if (r.statusCode == 401) await logout();
    return _m(r.data);
  }

  static Future<Map<String, dynamic>> failed(int parcelId, String reason) async {
    final r = await _dio.post('/delivery_failed', data: {'parcel_id': parcelId, 'reason': reason});
    if (r.statusCode == 401) await logout();
    return _m(r.data);
  }

  static Future<void> logout() => _store.delete(key: 'token');
}
