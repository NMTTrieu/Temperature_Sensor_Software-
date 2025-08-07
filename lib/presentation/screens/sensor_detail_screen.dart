import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/sensor_model.dart';
import '../../utils/signal_helper.dart';

class SensorDetailScreen extends StatelessWidget {
  final SensorModel sensor;

  const SensorDetailScreen({super.key, required this.sensor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          sensor.name,
          style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.green[600],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Temperature
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              child: ListTile(
                leading: Icon(Icons.thermostat, color: Colors.orange, size: 30),
                title: Text(
                  "Temperature",
                  style: GoogleFonts.roboto(fontSize: 16),
                ),
                trailing: Text(
                  "${sensor.temp} °C",
                  style: GoogleFonts.roboto(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            /// Humidity
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              child: ListTile(
                leading: Icon(Icons.water_drop, color: Colors.blue, size: 30),
                title: Text(
                  "Humidity",
                  style: GoogleFonts.roboto(fontSize: 16),
                ),
                trailing: Text(
                  "${sensor.humidity} %",
                  style: GoogleFonts.roboto(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            /// Status
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              child: SwitchListTile(
                activeColor: Colors.green,
                title: Text(
                  "Power Status",
                  style: GoogleFonts.roboto(fontSize: 16),
                ),
                value: sensor.status,
                onChanged: (value) {
                  // TODO: Cập nhật trạng thái ở đây
                },
              ),
            ),
            const SizedBox(height: 10),

            /// Signal
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              child: ListTile(
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(4, (index) {
                    return Container(
                      width: 6,
                      height: (index + 1) * 7.0,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: index < signalBars(sensor.signal)
                            ? Colors.green
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
                title: const Text("Signal Strength"),
                trailing: Text(
                  "${sensor.signal} dBm",
                  style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
