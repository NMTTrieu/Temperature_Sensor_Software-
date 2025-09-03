import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:my_app/models/telemetry_model.dart';

class TelemetryService {
  final String apiUrl;

  TelemetryService({
    this.apiUrl = 'https://be-mqtt-iot.onrender.com/api/telemetry?limit=1000',
  });

  Future<List<TelemetryModel>> fetchTelemetry() async {
    final res = await http.get(Uri.parse(apiUrl));
    if (res.statusCode != 200) {
      throw Exception('Lỗi tải dữ liệu: HTTP ${res.statusCode}');
    }
    final body = res.body.isEmpty ? '[]' : res.body;
    final jsonData = json.decode(body);
    final data = _parseJsonToTelemetryList(jsonData);
    // sort tăng dần
    data.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return data;
  }

  Future<List<TelemetryModel>> fetchTelemetryByDevice(String deviceId) async {
    final res = await http.get(Uri.parse('$apiUrl?deviceId=$deviceId'));
    if (res.statusCode != 200) {
      throw Exception('Lỗi tải dữ liệu thiết bị: HTTP ${res.statusCode}');
    }
    final body = res.body.isEmpty ? '[]' : res.body;
    final jsonData = json.decode(body);
    final data = _parseJsonToTelemetryList(jsonData);
    data.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return data;
  }

  /// Lấy telemetry theo deviceId + range ('1d' | '7d' | '30d' | '1y')
  /// Lọc LOCAL theo khoảng [start, end) và tất cả mốc thời gian đều về local.
  Future<List<TelemetryModel>> fetchTelemetryByDeviceAndRange(
    String deviceId, {
    String? range,
  }) async {
    final String url = '$apiUrl?deviceId=$deviceId';
    final res = await http.get(Uri.parse(url));

    if (res.statusCode != 200) {
      throw Exception(
        'Lỗi tải dữ liệu thiết bị theo khoảng thời gian: HTTP ${res.statusCode}',
      );
    }

    final body = res.body.isEmpty ? '[]' : res.body;
    final jsonData = json.decode(body);
    List<TelemetryModel> data = _parseJsonToTelemetryList(jsonData);

    if (data.isEmpty) return [];

    // Sắp xếp để tìm min - max
    data.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (range != null && range == '1d') {
      // Lấy tất cả record trong ngày của record muộn nhất
      final latest = data.last.timestamp; // record cuối cùng
      final startOfDay = DateTime(latest.year, latest.month, latest.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      data = data
          .where(
            (t) =>
                t.timestamp.isAfter(startOfDay) &&
                t.timestamp.isBefore(endOfDay),
          )
          .toList();

      // Đảm bảo lấy từ record sớm nhất -> muộn nhất trong ngày
      if (data.isNotEmpty) {
        final earliest = data.first.timestamp;
        final latestOfDay = data.last.timestamp;
        print('Earliest of day: $earliest, Latest of day: $latestOfDay');
      }
    } else if (range != null) {
      // Các range khác (7d, 30d, 1y)
      final now = DateTime.now();
      DateTime start;
      switch (range) {
        case '7d':
          start = now.subtract(const Duration(days: 7));
          break;
        case '30d':
          start = now.subtract(const Duration(days: 30));
          break;
        case '1y':
          start = now.subtract(const Duration(days: 365));
          break;
        default:
          start = now.subtract(const Duration(days: 7));
      }
      data = data.where((t) => t.timestamp.isAfter(start)).toList();
    }

    return data;
  }

  /// (Tùy chọn) Lấy theo khoảng thời gian cụ thể
  Future<List<TelemetryModel>> fetchTelemetryByDeviceBetween(
    String deviceId, {
    required DateTime from,
    required DateTime to,
  }) async {
    final data = await fetchTelemetryByDevice(deviceId);
    final local = data
        .map((t) => t.copyWith(timestamp: t.timestamp.toLocal()))
        .toList();
    final filtered = local.where((t) {
      final dt = t.timestamp;
      return !dt.isBefore(from) && dt.isBefore(to);
    }).toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return filtered;
  }

  // ------------------ Helpers ------------------

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
