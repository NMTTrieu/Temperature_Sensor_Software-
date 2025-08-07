import 'package:flutter/material.dart';
import '../../models/telemetry_model.dart';
import '../../utils/signal_helper.dart';
import 'info_row.dart';

class TelemetryCard extends StatelessWidget {
  final TelemetryModel telemetry;

  const TelemetryCard({super.key, required this.telemetry});

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
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          /// Location
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.green[600],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Container(
                    child: Text(
                      "${telemetry.deviceId}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    child: Text(
                      "model: ${telemetry.model}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),

          /// Sensor Info
          Expanded(
            flex: 6,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                /// Temp + Humidity
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InfoRow(
                      icon: Icons.thermostat,
                      text: "${telemetry.temperature} °C",
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Thời gian cập nhật gần nhất: ${telemetry.timestamp}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // InfoRow(
                    //   icon: Icons.water_drop,
                    //   text: "${sensor.humidity} %",
                    // ),
                  ],
                ),

                /// Status + Signal
                // Column(
                //   crossAxisAlignment: CrossAxisAlignment.start,
                //   children: [
                //     Row(
                //       children: [
                //         Icon(
                //           Icons.power_settings_new,
                //           color: sensor.status ? Colors.green : Colors.grey,
                //           size: 22,
                //         ),
                //         const SizedBox(width: 6),
                //         Text(
                //           sensor.status ? "On" : "Off",
                //           style: TextStyle(
                //             color: sensor.status ? Colors.green : Colors.grey,
                //             fontSize: 14,
                //           ),
                //         ),
                //       ],
                //     ),
                //     const SizedBox(height: 8),
                //     Row(
                //       children: [
                //         Row(
                //           mainAxisSize: MainAxisSize.min,
                //           crossAxisAlignment: CrossAxisAlignment.end,
                //           children: List.generate(4, (index) {
                //             return Container(
                //               width: 4,
                //               height: (index + 1) * 5.0,
                //               margin: const EdgeInsets.symmetric(horizontal: 1),
                //               decoration: BoxDecoration(
                //                 color: index < signalBars(sensor.signal)
                //                     ? Colors.green
                //                     : Colors.grey[300],
                //                 borderRadius: BorderRadius.circular(2),
                //               ),
                //             );
                //           }),
                //         ),
                //         const SizedBox(width: 6),
                //         Text(
                //           "${sensor.signal} dBm",
                //           style: const TextStyle(
                //             color: Colors.green,
                //             fontSize: 14,
                //           ),
                //         ),
                //       ],
                //     ),
                //   ],
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
