import 'dart:async';
import 'package:flutter/material.dart';

import 'package:my_app/notifications/notifier.dart';
import 'package:my_app/presentation/screens/telemetry_list_screen.dart';
import 'package:my_app/models/telemetry_model.dart';
import 'package:my_app/models/notification_model.dart';
import 'package:my_app/services/telemetry_service.dart';
import 'package:my_app/services/notification_service.dart';
import 'package:my_app/services/firebase_service.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;

  // Services
  final _api = TelemetryService(
    apiUrl: 'https://be-mqtt-iot.onrender.com/api/telemetry',
  );
  final _notifApi = NotificationService(
    baseUrl: 'https://be-mqtt-iot.onrender.com/api/notifications',
  );
  final _fb = FirebaseChangeListener(
    databaseUrl:
        'https://temperature-sensor-software-default-rtdb.firebaseio.com',
    path: 'telemrtry_updates',
  );

  // Device list state
  List<TelemetryModel> _devices = [];
  bool _loading = true;
  Object? _error;

  // Notification state
  bool _loadingNotifs = true;
  Object? _errorNotifs;
  List<NotificationModel> _allNotifs = [];
  List<NotificationModel> _unreadNotifs = [];
  List<NotificationModel> _readNotifs = [];

  // Local “đã đọc” (ghi khi đóng dialog)
  final Set<String> _readIdsLocal = {};
  static const _prefsKeyReadIds = 'notif_read_ids_v1';

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.9,
      upperBound: 1.05,
    )..repeat(reverse: true);

    _boot();
  }

  Future<void> _boot() async {
    // Khởi tạo thông báo cục bộ
    await Notifier.init();

    // Tải dữ liệu thiết bị và thông báo
    await _loadData();
    await _refreshNotifications();

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => TelemetryListScreen(
          devices: _devices,
          unreadNotifs: _unreadNotifs,
          readNotifs: _readNotifs,
        ),
      ),
    );
  }

  // Lấy danh sách thiết bị
  Future<void> _loadData() async {
    try {
      print("Bắt đầu tải dữ liệu thiết bị...");
      final all = await _api.fetchTelemetry().timeout(
        const Duration(seconds: 10),
      );
      print("Dữ liệu thiết bị tải về: ${all.length} bản ghi");
      final map = <String, TelemetryModel>{};
      for (final t in all) {
        final old = map[t.deviceId];
        if (old == null || t.timestamp.isAfter(old.timestamp)) {
          map[t.deviceId] = t;
        }
      }
      if (mounted) {
        setState(() {
          _devices = map.values.toList();
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      print("Lỗi tải dữ liệu: $e");
      if (mounted) {
        setState(() {
          _error = e is TimeoutException ? 'Kết nối timeout' : e.toString();
          _loading = false;
        });
      }
    }
  }

  // Làm mới danh sách thông báo
  Future<void> _refreshNotifications() async {
    try {
      print("Bắt đầu tải thông báo...");
      setState(() {
        _loadingNotifs = true;
        _errorNotifs = null;
      });
      final items = await _notifApi.fetchNotifications().timeout(
        const Duration(seconds: 10),
      );
      print("Thông báo tải về: ${items.length} bản ghi");
      _allNotifs = items;
      final unread = <NotificationModel>[];
      final read = <NotificationModel>[];
      for (final n in items) {
        final isRead = n.read == true || _readIdsLocal.contains(n.id);
        (isRead ? read : unread).add(n);
      }
      unread.sort((a, b) {
        final at =
            a.createdAt ??
            a.savedAt ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
        final bt =
            b.createdAt ??
            b.savedAt ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
        return bt.compareTo(at);
      });
      read.sort((a, b) {
        final at =
            a.createdAt ??
            a.savedAt ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
        final bt =
            b.createdAt ??
            b.savedAt ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
        return bt.compareTo(at);
      });
      if (mounted) {
        setState(() {
          _unreadNotifs = unread;
          _readNotifs = read;
          _loadingNotifs = false;
        });
      }
    } catch (e) {
      print("Lỗi tải thông báo: $e");
      if (mounted) {
        setState(() {
          _errorNotifs = e is TimeoutException
              ? 'Kết nối timeout'
              : e.toString();
          _loadingNotifs = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _ac.dispose();
    _fb.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _ac,
              child: Image.asset('assets/images/loading_icon.png', height: 160),
            ),
            const SizedBox(height: 18),
            Text(
              'SmartNode',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 24),
            if (_loading || _loadingNotifs) const CircularProgressIndicator(),
            if (_error != null || _errorNotifs != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Lỗi: ${_error ?? _errorNotifs}',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
