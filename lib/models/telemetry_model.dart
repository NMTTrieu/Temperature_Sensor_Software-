import 'package:intl/intl.dart';

class TelemetryModel {
  final String deviceId;
  final double temperature;
  final double humidity;
  final DateTime timestamp;
  final String? model;
  final String? type;
  final String? topic;
  final String? formattedTime;

  TelemetryModel({
    required this.deviceId,
    required this.temperature,
    required this.humidity,
    required this.timestamp,
    this.model,
    this.type,
    this.topic,
    this.formattedTime,
  });

  factory TelemetryModel.fromJson(Map<String, dynamic> json) {
    // API của bạn dùng 'timestamp'. Nếu nguồn khác dùng 'lastSeen' thì fallback
    final ts = DateTime.fromMillisecondsSinceEpoch(
      (json['timestamp'] ?? 0) as int,
    ).toLocal();

    final fmt = DateFormat('yyyy-MM-dd HH:mm:ss').format(ts);
    return TelemetryModel(
      deviceId: (json['deviceId'] ?? '').toString(),
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
      humidity: (json['humidity'] as num?)?.toDouble() ?? 0.0,
      timestamp: ts,
      model: json['model']?.toString(),
      type: json['type']?.toString(),
      topic: json['topic']?.toString(),
    );
  }

  String get key => '${deviceId}_${timestamp.millisecondsSinceEpoch}';
}
