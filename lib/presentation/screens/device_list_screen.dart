import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../models/device_model.dart';
import '../../services/device_service.dart';

class DeviceListScreen extends StatefulWidget {
  const DeviceListScreen({Key? key}) : super(key: key);

  @override
  State<DeviceListScreen> createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends State<DeviceListScreen> {
  late DatabaseReference firebaseRef;

  @override
  void initState() {
    super.initState();
    // Thay URL dưới bằng URL Realtime Database thực tế của bạn nếu cần
    firebaseRef = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL:
          'https://temperature-sensor-software-default-rtdb.firebaseio.com',
    ).ref('device_updates');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Danh sách thiết bị')),
      body: StreamBuilder<DatabaseEvent>(
        stream: firebaseRef.onValue,
        builder: (context, snapshot) {
          // Mỗi khi Firebase có thay đổi, ta gọi lại API
          return FutureBuilder<List<DeviceModel>>(
            future: fetchDeviceData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Lỗi: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('Không có thiết bị nào'));
              } else {
                final deviceList = snapshot.data!;
                return ListView.builder(
                  itemCount: deviceList.length,
                  itemBuilder: (context, index) {
                    final device = deviceList[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        title: Text(device.model),
                        subtitle: Text('ID: ${device.id}'),
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
