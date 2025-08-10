import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:my_app/models/device_model.dart';

/// Service đọc thông tin thiết bị từ /api/devices
class DeviceService {
  final String baseUrl;

  DeviceService({
    this.baseUrl = 'https://be-mqtt-iot.onrender.com/api/devices',
  });

  /// Backend trả list ⇒ tải 1 lần rồi lọc theo id
  Future<DeviceModel?> fetchDeviceById(String id) async {
    final res = await http.get(Uri.parse(baseUrl));
    if (res.statusCode != 200) {
      throw Exception('Lỗi tải devices: HTTP ${res.statusCode}');
    }

    final raw = res.body.isEmpty ? '[]' : res.body;
    final jsonData = json.decode(raw);

    if (jsonData is List) {
      for (final e in jsonData) {
        if (e is Map && e['id']?.toString() == id) {
          return DeviceModel.fromJson(e.cast<String, dynamic>());
        }
      }
    }
    return null;
  }
}
