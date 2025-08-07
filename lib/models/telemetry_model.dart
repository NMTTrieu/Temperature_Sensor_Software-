class TelemetryModel {
  final double temperature;
  final String deviceId;
  final String model;
  final String type;
  final String topic;
  final DateTime timestamp;

  TelemetryModel({
    required this.temperature,
    required this.deviceId,
    required this.model,
    required this.type,
    required this.topic,
    required this.timestamp,
  });

  factory TelemetryModel.fromJson(Map<String, dynamic> json) {
    return TelemetryModel(
      temperature: (json['temperature'] as num).toDouble(),
      deviceId: json['deviceId'],
      model: json['model'],
      type: json['type'],
      topic: json['topic'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'deviceId': deviceId,
      'model': model,
      'type': type,
      'topic': topic,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
