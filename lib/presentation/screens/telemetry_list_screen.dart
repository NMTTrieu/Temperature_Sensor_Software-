import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_app/models/telemetry_model.dart';
import 'package:my_app/models/notification_model.dart';
import 'package:my_app/services/telemetry_service.dart';
import 'package:my_app/services/notification_service.dart';
import 'package:my_app/services/firebase_service.dart';

import 'package:my_app/presentation/widgets/telemetry_card.dart';
import 'package:my_app/presentation/widgets/alert_badge.dart';
import 'package:my_app/presentation/screens/telemetry_detail_screen.dart';

class TelemetryListScreen extends StatefulWidget {
  const TelemetryListScreen({Key? key}) : super(key: key);

  @override
  State<TelemetryListScreen> createState() => _TelemetryListScreenState();
}

class _TelemetryListScreenState extends State<TelemetryListScreen> {
  // ====== Services ======
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

  // ====== Device list state ======
  List<TelemetryModel> _devices = [];
  bool _loading = true;
  Object? _error;

  // ====== Notification state ======
  bool _loadingNotifs = true;
  Object? _errorNotifs;

  List<NotificationModel> _allNotifs = [];
  List<NotificationModel> _unreadNotifs = [];
  List<NotificationModel> _readNotifs = [];

  // Local “đã đọc” (ghi khi đóng dialog)
  final Set<String> _readIdsLocal = {};
  static const _prefsKeyReadIds = 'notif_read_ids_v1';

  // UI constants
  static const double _notifItemHeight = 96.0;

  // ========== Lifecycle ==========
  @override
  void initState() {
    super.initState();
    _restoreReadIds();
    _loadData();
    _refreshNotifications();
    _fb.start(
      onChanged: () {
        if (mounted) {
          _loadData(silent: true);
          _refreshNotifications(); // để badge cập nhật sớm
        }
      },
    );
  }

  @override
  void dispose() {
    _fb.stop();
    super.dispose();
  }

  // ========== Persist read ids ==========
  Future<void> _persistReadIds() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setStringList(_prefsKeyReadIds, _readIdsLocal.toList());
  }

  Future<void> _restoreReadIds() async {
    final sp = await SharedPreferences.getInstance();
    final list = sp.getStringList(_prefsKeyReadIds) ?? [];
    _readIdsLocal
      ..clear()
      ..addAll(list);
    if (mounted) setState(() {});
  }

  // ========== Load devices ==========
  Future<void> _loadData({bool silent = false}) async {
    try {
      if (!silent) setState(() => _loading = true);
      final all = await _api.fetchTelemetry();

      // newest per deviceId
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
      if (!silent && mounted) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    }
  }

  // ========== Load notifications (split unread/read) ==========
  Future<void> _refreshNotifications() async {
    try {
      setState(() {
        _loadingNotifs = true;
        _errorNotifs = null;
      });

      final items = await _notifApi.fetchNotifications();
      _allNotifs = items;

      final unread = <NotificationModel>[];
      final read = <NotificationModel>[];

      for (final n in items) {
        final isRead = n.read == true || _readIdsLocal.contains(n.id);
        if (isRead) {
          read.add(n);
        } else {
          unread.add(n);
        }
      }

      int _cmp(NotificationModel a, NotificationModel b) {
        final at =
            a.createdAt ??
            a.savedAt ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
        final bt =
            b.createdAt ??
            b.savedAt ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
        return bt.compareTo(at);
      }

      unread.sort(_cmp);
      read.sort(_cmp);

      setState(() {
        _unreadNotifs = unread;
        _readNotifs = read;
        _loadingNotifs = false;
      });
    } catch (e) {
      setState(() {
        _errorNotifs = e;
        _loadingNotifs = false;
      });
    }
  }

  // ========== Dialog & filter ==========
  Future<void> _openNotificationsDialog() async {
    // snapshot tại thời điểm mở
    final unreadNow = List<NotificationModel>.from(_unreadNotifs);
    final readNow = List<NotificationModel>.from(_readNotifs);

    final seenIds = <String>{}; // chỉ ghi cho tab MỚI

    final result = await showDialog<Set<String>>(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        final controller = ScrollController();
        bool showUnread = true; // Mới / Đã đọc

        void captureVisible(ScrollMetrics m) {
          if (!showUnread) return; // chỉ đếm tab Mới
          if (unreadNow.isEmpty) return;
          final first = (m.pixels / _notifItemHeight).floor().clamp(
            0,
            unreadNow.length - 1,
          );
          final last = ((m.pixels + m.viewportDimension) / _notifItemHeight)
              .floor()
              .clamp(0, unreadNow.length - 1);
          for (int i = first; i <= last; i++) {
            seenIds.add(unreadNow[i].id);
          }
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (controller.hasClients) captureVisible(controller.position);
        });

        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final list = showUnread ? unreadNow : readNow;

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: SafeArea(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 560),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: filter (trái) + title
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
                        child: Row(
                          children: [
                            _filterSegment(
                              showUnread: showUnread,
                              onTapUnread: () {
                                setModalState(() => showUnread = true);
                                if (controller.hasClients) {
                                  captureVisible(controller.position);
                                }
                              },
                              onTapRead: () =>
                                  setModalState(() => showUnread = false),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Thông báo',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context, seenIds),
                              tooltip: 'Đóng',
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),

                      Expanded(
                        child: _loadingNotifs
                            ? const Center(child: CircularProgressIndicator())
                            : _errorNotifs != null
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    'Lỗi tải thông báo: $_errorNotifs',
                                  ),
                                ),
                              )
                            : list.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text('Không có thông báo'),
                                ),
                              )
                            : NotificationListener<ScrollNotification>(
                                onNotification: (n) {
                                  if (n.metrics.axis == Axis.vertical) {
                                    captureVisible(n.metrics);
                                  }
                                  return false;
                                },
                                child: ListView.separated(
                                  controller: controller,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  itemCount: list.length,
                                  separatorBuilder: (_, __) => const Divider(
                                    height: 1,
                                    indent: 16,
                                    endIndent: 16,
                                  ),
                                  itemBuilder: (context, i) {
                                    final n = list[i];
                                    return SizedBox(
                                      height: _notifItemHeight,
                                      child: ListTile(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                        title: Text(
                                          n.message.isEmpty
                                              ? 'Thiết bị ${n.deviceId}'
                                              : n.message,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        subtitle: Padding(
                                          padding: const EdgeInsets.only(
                                            top: 6,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Thiết bị: ${n.deviceId} · Model: ${n.deviceModel}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Nhiệt độ: ${n.temperature.toStringAsFixed(1)}°C · '
                                                'Ẩm: ${n.humidity.toStringAsFixed(1)}%',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Lúc: ${n.createdAtText}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        onTap: () {}, // Không đánh dấu khi chạm
                                      ),
                                    );
                                  },
                                ),
                              ),
                      ),

                      const Divider(height: 1),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 10, 16, 12),
                        child: Text(
                          'Cuộn để xem. Đóng để xác nhận đã xem các mục bạn đã lướt qua.',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    // sau khi đóng dialog
    final seen = result ?? <String>{};
    if (seen.isEmpty || !mounted) return;

    setState(() {
      // chuyển các item đã “lướt qua” từ unread sang read
      for (final id in seen) {
        _readIdsLocal.add(id);
      }
      final moved = _unreadNotifs.where((n) => _readIdsLocal.contains(n.id));
      _readNotifs.insertAll(0, moved);
      _unreadNotifs.removeWhere((n) => _readIdsLocal.contains(n.id));
    });
    await _persistReadIds();

    // (tuỳ chọn) gọi API đánh dấu đã đọc
    for (final id in seen) {
      _notifApi.markAsRead(id).catchError((_) {});
    }
  }

  // ========== Small widgets ==========
  Widget _filterSegment({
    required bool showUnread,
    required VoidCallback onTapUnread,
    required VoidCallback onTapRead,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.6),
      ),
      child: Row(
        children: [
          _segBtn(label: 'Mới', selected: showUnread, onTap: onTapUnread),
          _segBtn(label: 'Đã đọc', selected: !showUnread, onTap: onTapRead),
        ],
      ),
    );
  }

  Widget _segBtn({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: selected
              ? [const BoxShadow(color: Colors.black12, blurRadius: 4)]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: selected ? Colors.black : Colors.black87,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // ========== Body ==========
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

    return RefreshIndicator(
      onRefresh: () async {
        await _loadData();
        await _refreshNotifications();
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _devices.length,
        itemBuilder: (context, i) {
          final item = _devices[i];
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      TelemetryDetailScreen(deviceId: item.deviceId),
                ),
              ),
              child: TelemetryCard(telemetry: item),
            ),
          );
        },
      ),
    );
  }

  // ========== Build ==========
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách thiết bị'),
        actions: [
          AlertBadge(
            count: _unreadNotifs.length,
            onTap: _openNotificationsDialog,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }
}
