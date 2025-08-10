import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:my_app/models/notifications_model.dart';

class NotificationService {
  final String baseUrl;

  /// Đổi URL nếu bạn dùng endpoint khác
  NotificationService({
    this.baseUrl = 'https://be-mqtt-iot.onrender.com/api/notifications',
  });

  /// GET /api/notifications
  Future<List<NotificationModel>> fetchNotifications() async {
    final res = await http.get(Uri.parse(baseUrl));

    if (res.statusCode != 200) {
      throw Exception('Lỗi tải thông báo: HTTP ${res.statusCode}');
    }

    final body = res.body.isEmpty ? '{}' : res.body;
    final jsonData = json.decode(body);

    if (jsonData is Map && jsonData['data'] is List) {
      return (jsonData['data'] as List)
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    // Một số trường hợp API trả thẳng List
    if (jsonData is List) {
      return jsonData
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// (Tuỳ chọn) Đánh dấu đã đọc nếu backend hỗ trợ
  Future<void> markAsRead(String id) async {
    final url = '$baseUrl/$id/read';
    final res = await http.patch(Uri.parse(url));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        'Không thể đánh dấu đã đọc ($id): HTTP ${res.statusCode}',
      );
    }
  }
}
