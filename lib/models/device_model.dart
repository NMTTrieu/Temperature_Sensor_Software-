import 'package:intl/intl.dart';

/// Mô tả 1 thiết bị từ /api/devices
class DeviceModel {
  final String id; // vd: "temp_007"
  final String? model; // vd: "TI_SENSORTAG"
  final String? firmware; // vd: "v2.1.8"
  final String? type; // vd: "sensor"
  final String? topic; // vd: "device/sensor/temp_007"
  final DateTime? lastActive; // epoch millis -> DateTime(UTC)

  DeviceModel({
    required this.id,
    this.model,
    this.firmware,
    this.type,
    this.topic,
    this.lastActive,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    DateTime? _msToUtc(dynamic v) {
      if (v == null) return null;
      final n = v is num ? v.toInt() : int.tryParse(v.toString());
      if (n == null) return null;
      return DateTime.fromMillisecondsSinceEpoch(n, isUtc: true);
    }

    return DeviceModel(
      id: json['id']?.toString() ?? '',
      model: json['model']?.toString(),
      firmware: json['firmware']?.toString(),
      type: json['type']?.toString(),
      topic: json['topic']?.toString(),
      lastActive: _msToUtc(json['lastActive']),
    );
  }

  /// Format giờ Việt Nam
  static String formatVN(
    DateTime? utc, {
    String pattern = 'dd/MM/yyyy HH:mm:ss',
  }) {
    if (utc == null) return '';
    final vn = utc.add(const Duration(hours: 7));
    return DateFormat(pattern).format(vn);
  }
}
