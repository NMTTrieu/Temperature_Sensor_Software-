import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:my_app/models/telemetry_model.dart';

class TelemetryService {
  final String apiUrl;

  TelemetryService({
    this.apiUrl = 'https://be-mqtt-iot.onrender.com/api/telemetry',
  });

  /// Lấy toàn bộ telemetry
  Future<List<TelemetryModel>> fetchTelemetry() async {
    final res = await http.get(Uri.parse(apiUrl));

    if (res.statusCode != 200) {
      throw Exception('Lỗi tải dữ liệu: HTTP ${res.statusCode}');
    }

    final body = res.body.isEmpty ? '[]' : res.body;
    final jsonData = json.decode(body);

    return _parseJsonToTelemetryList(jsonData);
  }

  /// Lấy telemetry theo deviceId
  Future<List<TelemetryModel>> fetchTelemetryByDevice(String deviceId) async {
    final res = await http.get(Uri.parse('$apiUrl?deviceId=$deviceId'));

    if (res.statusCode != 200) {
      throw Exception('Lỗi tải dữ liệu thiết bị: HTTP ${res.statusCode}');
    }

    final body = res.body.isEmpty ? '[]' : res.body;
    final jsonData = json.decode(body);

    return _parseJsonToTelemetryList(jsonData);
  }

  /// Lấy telemetry theo deviceId và khoảng thời gian (ví dụ: "7d", "30d", "1y")
  /// Nếu API không hỗ trợ range, bạn có thể lọc ở client
  Future<List<TelemetryModel>> fetchTelemetryByDeviceAndRange(
    String deviceId, {
    String? range,
  }) async {
    final String url = range != null
        ? '$apiUrl?deviceId=$deviceId&range=$range'
        : '$apiUrl?deviceId=$deviceId';

    final res = await http.get(Uri.parse(url));

    if (res.statusCode != 200) {
      throw Exception(
        'Lỗi tải dữ liệu thiết bị theo khoảng thời gian: HTTP ${res.statusCode}',
      );
    }

    final body = res.body.isEmpty ? '[]' : res.body;
    final jsonData = json.decode(body);

    return _parseJsonToTelemetryList(jsonData);
  }

  /// Chuyển dữ liệu JSON thành List<TelemetryModel>
  List<TelemetryModel> _parseJsonToTelemetryList(dynamic jsonData) {
    if (jsonData is List) {
      return jsonData
          .map((e) => TelemetryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    if (jsonData is Map<String, dynamic> && jsonData['data'] is List) {
      return (jsonData['data'] as List)
          .map((e) => TelemetryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return [];
  }
}
