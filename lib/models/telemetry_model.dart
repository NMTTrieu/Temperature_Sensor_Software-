class TelemetryModel {
  final String deviceId;
  final double temperature;
  final DateTime timestamp;

  // Các field tuỳ chọn nếu API có (không bắt buộc)
  final String? model;
  final String? type;
  final String? topic;

  TelemetryModel({
    required this.deviceId,
    required this.temperature,
    required this.timestamp,
    this.model,
    this.type,
    this.topic,
  });

  factory TelemetryModel.fromJson(Map<String, dynamic> json) {
    // API của bạn dùng 'timestamp'. Nếu nguồn khác dùng 'lastSeen' thì fallback
    final ts = json['timestamp'] ?? json['lastSeen'];
    return TelemetryModel(
      deviceId: (json['deviceId'] ?? '').toString(),
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
      timestamp: ts != null ? DateTime.parse(ts.toString()) : DateTime.now(),
      model: json['model']?.toString(),
      type: json['type']?.toString(),
      topic: json['topic']?.toString(),
    );
  }

  String get key => '${deviceId}_${timestamp.millisecondsSinceEpoch}';
}
