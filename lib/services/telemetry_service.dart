import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/telemetry_model.dart';

Future<List<TelemetryModel>> fetchTelemetryData() async {
  final url = Uri.parse('https://be-mqtt-iot.onrender.com/api/telemetry');

  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => TelemetryModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load telemetry: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Exception: $e');
  }
}
