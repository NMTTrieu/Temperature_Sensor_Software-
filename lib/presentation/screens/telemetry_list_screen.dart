import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:my_app/presentation/screens/device_list_screen.dart';
import 'package:my_app/presentation/widgets/telemetry_card.dart';
import '../../models/telemetry_model.dart';
import '../../services/telemetry_service.dart';

class TelemetryListScreen extends StatefulWidget {
  const TelemetryListScreen({Key? key}) : super(key: key);

  @override
  State<TelemetryListScreen> createState() => _TelemetryListScreenState();
}

class _TelemetryListScreenState extends State<TelemetryListScreen> {
  late DatabaseReference firebaseRef;

  List<TelemetryModel> getLatestPerDevice(List<TelemetryModel> list) {
    final Map<String, TelemetryModel> latestMap = {};

    for (var item in list) {
      final id = item.deviceId;
      if (!latestMap.containsKey(id) ||
          item.timestamp.isAfter(latestMap[id]!.timestamp)) {
        latestMap[id] = item;
      }
    }

    return latestMap.values.toList();
  }

  @override
  void initState() {
    super.initState();
    // Thay URL dưới bằng URL Realtime Database thực tế của bạn nếu cần
    firebaseRef = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL:
          'https://temperature-sensor-software-default-rtdb.firebaseio.com',
    ).ref('telemrtry_updates');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Danh sách thiết bị')),
      body: StreamBuilder<DatabaseEvent>(
        stream: firebaseRef.onValue,
        builder: (context, snapshot) {
          // Mỗi khi Firebase có thay đổi, ta gọi lại API
          return FutureBuilder<List<TelemetryModel>>(
            future: fetchTelemetryData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Lỗi: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('Không có thiết bị nào'));
              } else {
                final telemetryList = getLatestPerDevice(snapshot.data!);
                return ListView.builder(
                  itemCount: telemetryList.length,
                  itemBuilder: (context, index) {
                    final telemetry = telemetryList[index];
                    return Padding(
                      padding: const EdgeInsets.all(12),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DeviceListScreen(),
                            ),
                          );
                        },
                        child: TelemetryCard(telemetry: telemetry),
                      ),
                    );
                  },
                );
              }
            },
          );
        },
      ),
    );
  }
}
