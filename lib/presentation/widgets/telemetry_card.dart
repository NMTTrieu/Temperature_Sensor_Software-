import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/models/telemetry_model.dart';
import 'info_row.dart';

class TelemetryCard extends StatelessWidget {
  final TelemetryModel telemetry;
  const TelemetryCard({Key? key, required this.telemetry}) : super(key: key);
  static const double _threshold = 37.0;
  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm:ss').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          /// Device Info
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green[600],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    telemetry.deviceId ?? 'Unknown ID',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Model: ${telemetry.model ?? 'N/A'}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),

          /// Sensor Info
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InfoRow(
                  icon: Icons.thermostat,
                  text:
                      "${telemetry.temperature?.toStringAsFixed(1) ?? '--'} °C",
                  status: telemetry.temperature < _threshold ? 0 : 1,
                ),
                const SizedBox(height: 4),
                // InfoRow(
                //   icon: Icons.water_drop,
                //   text: "${telemetry.humidity?.toStringAsFixed(1) ?? '--'} %",
                // ),
                // const SizedBox(height: 8),
                Text(
                  "Cập nhật: ${_formatDate(telemetry.timestamp)}",
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
