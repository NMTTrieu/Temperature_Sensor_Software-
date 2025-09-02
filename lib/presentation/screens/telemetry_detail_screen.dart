// lib/presentation/screens/telemetry_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import 'package:my_app/services/telemetry_service.dart';
import 'package:my_app/models/telemetry_model.dart';
import 'package:my_app/models/device_model.dart';
import 'package:my_app/services/device_service.dart';

class TelemetryDetailScreen extends StatefulWidget {
  final String deviceId;
  const TelemetryDetailScreen({super.key, required this.deviceId});

  @override
  State<TelemetryDetailScreen> createState() => _TelemetryDetailScreenState();
}

class _TelemetryDetailScreenState extends State<TelemetryDetailScreen> {
  final _telemetryService = TelemetryService();
  final _deviceService = DeviceService();

  DeviceModel? _device;

  // Dữ liệu biểu đồ
  List<DateTime> _xTimes = [];
  List<FlSpot> _tempSpots = [];
  List<FlSpot> _humSpots = [];

  bool _loading = true;
  Object? _error;

  String _range = '7d';

  static const _rangeOptions = <String, String>{
    '1d': 'Hôm nay',
    '7d': '7 ngày',
    '30d': '30 ngày',
    '1y': '1 năm',
  };

  @override
  void initState() {
    super.initState();
    _refresh(); // load device + telemetry
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _deviceService.fetchDeviceById(widget.deviceId),
        _telemetryService.fetchTelemetryByDeviceAndRange(
          widget.deviceId,
          range: _range,
        ),
      ]);

      final device = results[0] as DeviceModel?;
      final data = (results[1] as List<TelemetryModel>)
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      final times = <DateTime>[];
      final tSpots = <FlSpot>[];
      final hSpots = <FlSpot>[];
      for (var i = 0; i < data.length; i++) {
        times.add(data[i].timestamp);
        tSpots.add(FlSpot(i.toDouble(), data[i].temperature.toDouble()));
        hSpots.add(FlSpot(i.toDouble(), data[i].humidity.toDouble()));
      }

      setState(() {
        _device = device;
        _xTimes = times;
        _tempSpots = tSpots;
        _humSpots = hSpots;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  String _formatXLabel(DateTime time) {
    final duration = _xTimes.isNotEmpty
        ? _xTimes.last.difference(_xTimes.first).inHours / 24
        : 0;
    if (duration <= 1) {
      return DateFormat('HH:mm').format(time); // Hiển thị giờ nếu ≤ 1 ngày
    }
    switch (_range) {
      case '7d':
      case '30d':
        return DateFormat('d/M').format(time); // Hiển thị ngày nếu > 1 ngày
      case '1y':
      default:
        return DateFormat('MM/yyyy').format(time); // Hiển thị tháng
    }
  }

  /// Thông tin thiết bị
  Widget _buildDeviceHeader() {
    final d = _device;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: d == null
          ? const Text('Không tìm thấy thông tin thiết bị')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      width: 130,
                      child: Text(
                        "Tên thiết bị",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        ': ${d.id.toUpperCase()}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                _kv('Kiểu máy', d.model ?? '-'),
                _kv('Phần mềm', d.firmware ?? '-'),
                _kv('Loại thiết bị', d.type ?? '-'),
                _kv('Hoạt động gần nhất', DeviceModel.formatVN(d.lastActive)),
              ],
            ),
    );
  }

  Widget _kv(String k, String v) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            k,
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            ': $v',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );

  /// Vẽ 1 biểu đồ
  Widget _buildChart({
    required List<FlSpot> spots,
    required Color stroke,
    required List<Color> fill,
    required String yUnitSuffix, // '°C' | '%'
    double? fixedMinY,
    double? fixedMaxY,
  }) {
    final minY = spots.isEmpty
        ? (fixedMinY ?? 0.0)
        : (fixedMinY ??
              (spots.map((e) => e.y).reduce((a, b) => a < b ? a : b) - 0.5));
    final maxY = spots.isEmpty
        ? (fixedMaxY ?? 1.0)
        : (fixedMaxY ??
              (spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 0.5));

    final yRange = (maxY - minY).abs();
    final yInterval = yRange <= 5 ? 1.0 : (yRange / 5).ceilToDouble();

    final step = spots.length <= 8 ? 1 : (_xTimes.length / 8).ceil();
    final double minX = 0;
    final double maxX = spots.isEmpty ? 1 : (spots.length - 1).toDouble();

    // giá trị x đầu/cuối (để chỉ hiện dot ở 2 mốc này)
    final double? firstX = spots.isNotEmpty ? spots.first.x : null;
    final double? lastX = spots.isNotEmpty ? spots.last.x : null;

    // Tạo danh sách mốc thời gian cố định nếu ≤ 1 ngày
    List<DateTime> timeTicks = [];
    if (_xTimes.isNotEmpty &&
        _xTimes.last.difference(_xTimes.first).inHours / 24 <= 1) {
      final start = _xTimes.first.toLocal();
      final end = _xTimes.last.toLocal();
      var current = DateTime(
        start.year,
        start.month,
        start.day,
        start.hour,
        start.minute,
      );
      while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
        timeTicks.add(current);
        current = current.add(const Duration(minutes: 30)); // Mốc 30 phút
      }
      // Đảm bảo bao gồm mốc cuối cùng
      if (!timeTicks.contains(end)) {
        timeTicks.add(end);
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: spots.isEmpty
            ? const Center(child: Text('Không có dữ liệu'))
            : LineChart(
                LineChartData(
                  minX: minX,
                  maxX: maxX,
                  minY: minY,
                  maxY: maxY,
                  lineTouchData: LineTouchData(
                    enabled: true,
                    handleBuiltInTouches: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => Colors.white,
                      tooltipBorderRadius: BorderRadius.circular(10),
                      tooltipPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      // Tooltip CHỈ hiển thị giá trị (không kèm thời gian)
                      getTooltipItems: (touched) => touched
                          .map(
                            (t) => LineTooltipItem(
                              '${t.y.toStringAsFixed(1)} $yUnitSuffix',
                              TextStyle(
                                color: Colors.grey[800],
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    // Đường dọc + chấm tại vị trí chạm
                    getTouchedSpotIndicator: (bar, spotIndexes) {
                      return spotIndexes
                          .map(
                            (i) => TouchedSpotIndicatorData(
                              FlLine(
                                color: stroke.withValues(alpha: 0.6),
                                strokeWidth: 1,
                                dashArray: const [4, 3],
                              ),
                              FlDotData(
                                show: true,
                                getDotPainter: (s, __, ___, ____) =>
                                    FlDotCirclePainter(
                                      radius: 4.5,
                                      color: Colors.white,
                                      strokeColor: stroke,
                                      strokeWidth: 2.5,
                                    ),
                              ),
                            ),
                          )
                          .toList();
                    },
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    drawHorizontalLine: true,
                    getDrawingHorizontalLine: (v) => FlLine(
                      color: Colors.grey.withValues(alpha: 0.12),
                      strokeWidth: 1,
                      dashArray: const [8, 4],
                    ),
                    getDrawingVerticalLine: (v) => FlLine(
                      color: Colors.grey.withValues(alpha: 0.12),
                      strokeWidth: 1,
                      dashArray: const [8, 4],
                    ),
                    verticalInterval: step.toDouble(),
                    horizontalInterval: yInterval,
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 48,
                        interval: yInterval,
                        getTitlesWidget: (value, meta) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            value % 1 == 0
                                ? value.toStringAsFixed(0)
                                : value.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        interval:
                            maxX /
                            (timeTicks.length > 0
                                    ? timeTicks.length - 1
                                    : _xTimes.length - 1)
                                .toDouble(),
                        getTitlesWidget: (value, meta) {
                          if (_xTimes.isEmpty) return const SizedBox.shrink();
                          if (timeTicks.isNotEmpty) {
                            final tickIdx =
                                (value / maxX * (timeTicks.length - 1)).round();
                            if (tickIdx >= 0 && tickIdx < timeTicks.length) {
                              final label = _formatXLabel(timeTicks[tickIdx]);
                              if (tickIdx > 0) {
                                final prevLabel = _formatXLabel(
                                  timeTicks[tickIdx - 1],
                                );
                                if (prevLabel == label)
                                  return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }
                          }
                          final idx = (value / maxX * (_xTimes.length - 1))
                              .round();
                          if (idx < 0 || idx >= _xTimes.length)
                            return const SizedBox.shrink();
                          final label = _formatXLabel(_xTimes[idx]);
                          if (idx > 0 &&
                              _formatXLabel(_xTimes[idx - 1]) == label) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.08),
                      width: 1,
                    ),
                  ),
                  // Chỉ vẽ DOT ở đầu và cuối đường
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: false,
                      barWidth: 3.5,
                      color: stroke,
                      gradient: LinearGradient(
                        colors: [stroke, stroke.withValues(alpha: 0.75)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      dotData: FlDotData(
                        show: true,
                        // chỉ hiện dot ở x đầu và x cuối
                        checkToShowDot: (spot, barData) {
                          if (firstX == null || lastX == null) return false;
                          return spot.x == firstX || spot.x == lastX;
                        },
                        getDotPainter: (s, __, ___, ____) => FlDotCirclePainter(
                          radius: 4.5,
                          color: Colors.white,
                          strokeColor: stroke,
                          strokeWidth: 2.5,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            stroke.withValues(alpha: 0.25),
                            fill.last.withValues(alpha: 0.08),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeInOut,
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('THÔNG TIN THIẾT BỊ'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDeviceHeader(),

                Row(
                  children: [
                    Text(
                      'BIỂU ĐỒ',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    DropdownButton<String>(
                      value: _range,
                      underline: const SizedBox.shrink(),
                      items: _rangeOptions.entries
                          .map(
                            (e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value),
                            ),
                          )
                          .toList(),
                      onChanged: (v) async {
                        if (v == null) return;
                        _range = v;
                        await _refresh();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (_loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_error != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Lỗi: $_error'),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _refresh,
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Nhiệt độ (°C)',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _buildChart(
                    spots: _tempSpots,
                    stroke: const Color(0xFF1E88E5),
                    fill: const [Color(0xFF90CAF9)],
                    yUnitSuffix: '°C',
                  ),
                  const SizedBox(height: 20),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Độ ẩm (%)',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _buildChart(
                    spots: _humSpots,
                    stroke: const Color(0xFF2E7D32),
                    fill: const [Color(0xFFA5D6A7)],
                    yUnitSuffix: '%',
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
