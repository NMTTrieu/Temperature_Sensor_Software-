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
    final ts = DateTime.fromMillisecondsSinceEpoch(
      (json['timestamp'] ?? 0) as int,
      isUtc: true, // đảm bảo parse UTC
    ).toLocal(); // convert sang local

    return TelemetryModel(
      deviceId: (json['deviceId'] ?? '').toString(),
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
      humidity: (json['humidity'] as num?)?.toDouble() ?? 0.0,
      timestamp: ts,
      model: json['model']?.toString(),
      type: json['type']?.toString(),
      topic: json['topic']?.toString(),
      formattedTime: DateFormat('yyyy-MM-dd HH:mm:ss').format(ts),
    );
  }

  /// Thêm hàm copyWith để tiện thay timestamp hoặc field khác
  TelemetryModel copyWith({
    String? deviceId,
    double? temperature,
    double? humidity,
    DateTime? timestamp,
    String? model,
    String? type,
    String? topic,
    String? formattedTime,
  }) {
    return TelemetryModel(
      deviceId: deviceId ?? this.deviceId,
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      timestamp: timestamp ?? this.timestamp,
      model: model ?? this.model,
      type: type ?? this.type,
      topic: topic ?? this.topic,
      formattedTime: formattedTime ?? this.formattedTime,
    );
  }

  String get key => '${deviceId}_${timestamp.millisecondsSinceEpoch}';
}
