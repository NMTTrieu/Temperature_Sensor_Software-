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
  List<TelemetryModel> _allData = []; // Lưu toàn bộ dữ liệu tải về

  // Dữ liệu biểu đồ
  List<DateTime> _xTimes = [];
  List<FlSpot> _tempSpots = [];
  List<FlSpot> _humSpots = [];

  bool _loading = true;
  Object? _error;

  String _range = '30d'; // Mặc định là 30 ngày
  bool _userOverrodeRange = false; // Người dùng đã thay đổi phạm vi thủ công?

  static const _rangeOptions = <String, String>{
    '1d': 'Hôm nay',
    '7d': '7 ngày',
    '30d': '30 ngày',
  };

  @override
  void initState() {
    super.initState();
    _loadInitialData(); // Load dữ liệu 30 ngày khi khởi tạo
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _deviceService.fetchDeviceById(widget.deviceId),
        _telemetryService.fetchTelemetryByDeviceAndRange(
          widget.deviceId,
          range: '30d',
        ), // Load dữ liệu 30 ngày
      ]);

      final device = results[0] as DeviceModel?;
      final data = (results[1] as List<TelemetryModel>)
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      setState(() {
        _device = device;
        _allData = data;
        _updateChartData(); // Cập nhật biểu đồ dựa trên _range mặc định (30 ngày)
        _loading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  void _updateChartData() {
    final times = <DateTime>[];
    final tSpots = <FlSpot>[];
    final hSpots = <FlSpot>[];
    final now = DateTime.now().toLocal(); // 12:52 AM +07, 05/09/2025
    final startOfDay = DateTime(now.year, now.month, now.day);

    if (_allData.isEmpty) {
      times.add(now);
      setState(() {
        _xTimes = times;
        _tempSpots = tSpots;
        _humSpots = hSpots;
      });
      return;
    }

    DateTime startDate;
    int daysAgo = 0;

    if (_range == '1d') {
      startDate = startOfDay;
    } else if (_range == '7d') {
      daysAgo = 7;
      startDate = now.subtract(Duration(days: daysAgo));
    } else if (_range == '30d') {
      daysAgo = 30;
      startDate = now.subtract(Duration(days: daysAgo));
    } else {
      startDate = startOfDay;
    }

    // Tìm giá trị gần nhất trước startDate
    TelemetryModel? nearestBeforeStart;
    double startTemperature = 0.0;
    double startHumidity = 0.0;
    final relevantData = _allData
        .where((t) => t.timestamp.isBefore(startDate))
        .toList();
    if (relevantData.isNotEmpty) {
      relevantData.sort(
        (a, b) => b.timestamp.compareTo(a.timestamp),
      ); // Sắp xếp giảm dần để lấy gần nhất
      nearestBeforeStart = relevantData.first;
    } else {
      // Nếu không có dữ liệu trước startDate, lấy dữ liệu gần nhất sau startDate
      final afterData = _allData
          .where((t) => t.timestamp.isAfter(startDate))
          .toList();
      if (afterData.isNotEmpty) {
        afterData.sort(
          (a, b) => a.timestamp.compareTo(b.timestamp),
        ); // Sắp xếp tăng dần để lấy gần nhất
        nearestBeforeStart = afterData.first;
        startDate = nearestBeforeStart
            .timestamp; // Thay đổi startDate thành ngày của dữ liệu gần nhất
      }
    }

    if (nearestBeforeStart != null) {
      startTemperature = nearestBeforeStart.temperature;
      startHumidity = nearestBeforeStart.humidity;
    }

    times.add(startDate); // Bắt đầu từ startDate
    tSpots.add(FlSpot(0, startTemperature));
    hSpots.add(FlSpot(0, startHumidity));

    // Lọc dữ liệu trong khoảng thời gian
    final filteredData = _allData.where((t) {
      final diff = now.difference(t.timestamp).inDays.abs();
      return diff <= daysAgo;
    }).toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    for (int i = 0; i < filteredData.length; i++) {
      final dataPoint = filteredData[i];
      final xIndex = (i + 1) * (times.length - 1) ~/ filteredData.length;
      times.add(dataPoint.timestamp);
      tSpots.add(FlSpot(xIndex.toDouble(), dataPoint.temperature));
      hSpots.add(FlSpot(xIndex.toDouble(), dataPoint.humidity));
    }

    times.add(now); // Điểm cuối là ngày hiện tại
    if (filteredData.isNotEmpty) {
      tSpots.add(
        FlSpot((times.length - 1).toDouble(), filteredData.last.temperature),
      );
      hSpots.add(
        FlSpot((times.length - 1).toDouble(), filteredData.last.humidity),
      );
    } else {
      tSpots.add(FlSpot((times.length - 1).toDouble(), startTemperature));
      hSpots.add(FlSpot((times.length - 1).toDouble(), startHumidity));
    }

    setState(() {
      _xTimes = times;
      _tempSpots = tSpots;
      _humSpots = hSpots;
    });
  }

  String _formatXLabel(int index) {
    if (index < 0 || index >= _xTimes.length) {
      print('Invalid index: $index, _xTimes length: ${_xTimes.length}');
      return '';
    }
    final dt = _xTimes[index].toLocal();
    switch (_range) {
      case '1d':
        return DateFormat(
          'HH:mm',
        ).format(dt); // Hiển thị giờ:phút cho "Hôm nay"
      case '7d':
      case '30d':
        return DateFormat('d/M').format(dt); // Hiển thị ngày/tháng cho 7d, 30d
    }
    return '';
  }

  /// Card thông tin thiết bị (model/firmware/type/topic/lastActive)
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

  /// Vẽ 1 chart (nhiệt độ hoặc độ ẩm)
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
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((touchedSpot) {
                          final index = touchedSpot.spotIndex;
                          final yValue = touchedSpot.y.toStringAsFixed(1);
                          String timeLabel;
                          if (index >= 0 && index < _xTimes.length) {
                            final dt = _xTimes[index].toLocal();
                            timeLabel = _range == '1d'
                                ? DateFormat('HH:mm').format(
                                    dt,
                                  ) // Giờ:phút cho "Hôm nay"
                                : DateFormat(
                                    'd/M',
                                  ).format(dt); // Ngày/tháng cho 7d, 30d
                          } else {
                            timeLabel = 'N/A';
                          }
                          return LineTooltipItem(
                            '$yValue $yUnitSuffix\n$timeLabel',
                            TextStyle(
                              color: Colors.grey[800],
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          );
                        }).toList();
                      },
                    ),
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
                        interval:
                            (maxY -
                            minY), // Đặt interval bằng toàn bộ phạm vi để chỉ hiển thị 2 nhãn
                        getTitlesWidget: (value, meta) {
                          if (value == minY || value == maxY) {
                            return Padding(
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
                            );
                          }
                          return const SizedBox.shrink(); // Ẩn các nhãn khác
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        interval: step.toDouble(),
                        getTitlesWidget: (value, meta) {
                          final idx = value.round();
                          if (idx < 0 || idx >= _xTimes.length)
                            return const SizedBox.shrink();
                          final label = _formatXLabel(idx);
                          if (idx > 0 && _formatXLabel(idx - 1) == label) {
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
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true, // Thêm đường cong để hiển thị mượt hơn
                      barWidth: 2.0,
                      color: stroke,
                      gradient: LinearGradient(
                        colors: [stroke, stroke.withValues(alpha: 0.75)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      dotData: FlDotData(
                        show: false, // Ẩn dot để tập trung vào đường cong
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
        onRefresh: _loadInitialData, // Chỉ load lại khi kéo refresh
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
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() {
                          _userOverrodeRange =
                              true; // Đánh dấu người dùng đã chọn
                          _range = v;
                          _updateChartData(); // Cập nhật biểu đồ mà không load lại
                        });
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
                            onPressed: _loadInitialData,
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
