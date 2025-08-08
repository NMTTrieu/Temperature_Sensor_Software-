import 'package:flutter/material.dart';
import 'package:my_app/presentation/screens/telemetry_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/models/telemetry_model.dart';
import 'package:my_app/services/telemetry_service.dart';
import 'package:my_app/services/firebase_service.dart';
import 'package:my_app/presentation/widgets/telemetry_card.dart';
import 'package:my_app/presentation/widgets/alert_badge.dart';

class TelemetryListScreen extends StatefulWidget {
  const TelemetryListScreen({Key? key}) : super(key: key);

  @override
  State<TelemetryListScreen> createState() => _TelemetryListScreenState();
}

class _TelemetryListScreenState extends State<TelemetryListScreen> {
  final _api = TelemetryService(
    apiUrl: 'https://be-mqtt-iot.onrender.com/api/telemetry',
  );
  final _fb = FirebaseChangeListener(
    databaseUrl:
        'https://temperature-sensor-software-default-rtdb.firebaseio.com',
    path: 'telemrtry_updates',
  );

  static const double _threshold = 37.0;

  // state
  List<TelemetryModel> _devices = [];
  List<TelemetryModel> _unreadAlerts = [];
  final Set<String> _readKeys = {}; // khoá các cảnh báo đã đọc

  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _restoreReadState();
    _loadData(); // tải lần đầu

    // Nghe realtime từ Firebase: khi có thay đổi -> gọi lại API (debounce sẵn)
    _fb.start(
      onChanged: () {
        // chỉ refresh nền nếu đang mở màn
        if (mounted) _loadData(silent: true);
      },
    );
  }

  @override
  void dispose() {
    _fb.stop();
    super.dispose();
  }

  // Tạo khoá duy nhất cho 1 alert
  String _keyOf(TelemetryModel t) => t.key;

  Future<void> _persistReadState() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setStringList('readAlertKeys', _readKeys.toList());
  }

  Future<void> _restoreReadState() async {
    final sp = await SharedPreferences.getInstance();
    final saved = sp.getStringList('readAlertKeys') ?? [];
    _readKeys.addAll(saved);
    setState(() {});
  }

  Future<void> _loadData({bool silent = false}) async {
    try {
      if (!silent) {
        setState(() {
          _loading = true;
          _error = null;
        });
      }

      final all = await _api.fetchTelemetry();

      // lấy bản ghi mới nhất theo device
      final latestMap = <String, TelemetryModel>{};
      for (final t in all) {
        final id = t.deviceId;
        final old = latestMap[id];
        if (old == null || t.timestamp.isAfter(old.timestamp)) {
          latestMap[id] = t;
        }
      }

      // lọc cảnh báo chưa đọc
      final alerts = <TelemetryModel>[];
      for (final t in all) {
        if (t.temperature >= _threshold && !_readKeys.contains(_keyOf(t))) {
          alerts.add(t);
        }
      }

      setState(() {
        _devices = latestMap.values.toList();
        _unreadAlerts = alerts;
        _loading = false;
      });
    } catch (e) {
      if (!silent) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    }
  }

  void _markAsRead(TelemetryModel t) {
    final k = _keyOf(t);
    _readKeys.add(k);
    _unreadAlerts.removeWhere((x) => _keyOf(x) == k);
    setState(() {});
    _persistReadState();
  }

  void _markAllAsRead() {
    for (final t in _unreadAlerts) {
      _readKeys.add(_keyOf(t));
    }
    _unreadAlerts.clear();
    setState(() {});
    _persistReadState();
  }

  void _showAlertsDialog() {
    if (_unreadAlerts.isEmpty) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cảnh báo nhiệt độ cao'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _unreadAlerts.length,
            itemBuilder: (context, i) {
              final a = _unreadAlerts[i];
              return ListTile(
                title: Text('Thiết bị: ${a.deviceId}'),
                subtitle: Text(
                  'Nhiệt độ: ${a.temperature.toStringAsFixed(1)}°C\n'
                  'Lúc: ${a.timestamp.toLocal()}',
                ),
                trailing: TextButton(
                  onPressed: () => _markAsRead(a),
                  child: const Text('Đã đọc'),
                ),
                onTap: () => _markAsRead(a),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: const Text('Đánh dấu tất cả đã đọc'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Lỗi: $_error'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }
    if (_devices.isEmpty) {
      return const Center(child: Text('Không có thiết bị nào'));
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _devices.length,
      itemBuilder: (context, i) {
        final item = _devices[i];
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      TelemetryDetailScreen(deviceId: item.deviceId),
                ),
              );
            },
            child: TelemetryCard(telemetry: item),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách thiết bị'),
        actions: [
          AlertBadge(count: _unreadAlerts.length, onTap: _showAlertsDialog),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData, // kéo để tải lại từ API
        child: _buildBody(),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _loadData, // nút refresh thủ công
      //   child: const Icon(Icons.refresh),
      // ),
    );
  }
}
