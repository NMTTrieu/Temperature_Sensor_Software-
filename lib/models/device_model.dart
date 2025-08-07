class DeviceModel {
  final String id;
  final String model;
  final String firmware;
  final String type;
  final DateTime lastSeen;
  final String topic;

  DeviceModel({
    required this.id,
    required this.model,
    required this.firmware,
    required this.type,
    required this.lastSeen,
    required this.topic,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'],
      model: json['model'],
      firmware: json['firmware'],
      type: json['type'],
      lastSeen: DateTime.parse(json['lastSeen']),
      topic: json['topic'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'model': model,
      'firmware': firmware,
      'type': type,
      'lastSeen': lastSeen.toIso8601String(),
      'topic': topic,
    };
  }
}
