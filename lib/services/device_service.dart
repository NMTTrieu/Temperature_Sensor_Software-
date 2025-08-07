import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/device_model.dart';

Future<List<DeviceModel>> fetchDeviceData() async {
  final url = Uri.parse('https://be-mqtt-iot.onrender.com/api/devices');

  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => DeviceModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load devices: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Exception: $e');
  }
}
