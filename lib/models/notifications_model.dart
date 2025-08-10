import 'package:intl/intl.dart';

class NotificationModel {
  final String id;
  final double temperature;
  final double humidity;
  final String message;
  final String deviceId;
  final String deviceModel;
  final String deviceType;
  final String topic;
  final String triggeredBy;

  /// Thời gian đã format sẵn (giờ Việt Nam)
  final String createdAtText;
  final String savedAtText;
  final bool read;

  /// Giữ nguyên giá trị thô nếu bạn cần dùng tiếp (tùy chọn)
  final DateTime? createdAt; // UTC
  final DateTime? savedAt; // UTC

  NotificationModel({
    required this.id,
    required this.temperature,
    required this.humidity,
    required this.message,
    required this.deviceId,
    required this.deviceModel,
    required this.deviceType,
    required this.topic,
    required this.triggeredBy,
    required this.createdAtText,
    required this.savedAtText,
    required this.read,
    this.createdAt,
    this.savedAt,
  });

  /// Parse từ JSON (createdAt/savedAt là milliseconds)
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final createdUtc = _toUtc(json['createdAt']);
    final savedUtc = _toUtc(json['savedAt']);

    return NotificationModel(
      id: json['id'] ?? '',
      temperature: (json['temperature'] ?? 0).toDouble(),
      humidity: (json['humidity'] ?? 0).toDouble(),
      message: json['message'] ?? '',
      deviceId: json['deviceId'] ?? '',
      deviceModel: json['deviceModel'] ?? '',
      deviceType: json['deviceType'] ?? '',
      topic: json['topic'] ?? '',
      triggeredBy: json['triggeredBy'] ?? '',
      createdAtText: _formatVN(createdUtc),
      savedAtText: _formatVN(savedUtc),
      read: json['read'] ?? false,
      createdAt: createdUtc,
      savedAt: savedUtc,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'temperature': temperature,
    'humidity': humidity,
    'message': message,
    'deviceId': deviceId,
    'deviceModel': deviceModel,
    'deviceType': deviceType,
    'topic': topic,
    'triggeredBy': triggeredBy,
    'createdAt': createdAt?.millisecondsSinceEpoch,
    'savedAt': savedAt?.millisecondsSinceEpoch,
    'read': read,
  };

  // ---- Helpers ----
  static DateTime? _toUtc(dynamic millis) {
    if (millis == null) return null;
    final m = millis is num ? millis.toInt() : int.tryParse(millis.toString());
    if (m == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(m, isUtc: true);
  }

  static String _formatVN(DateTime? utc) {
    if (utc == null) return '';
    final vn = utc.add(const Duration(hours: 7));
    return DateFormat('dd/MM/yyyy HH:mm:ss').format(vn);
  }
}
