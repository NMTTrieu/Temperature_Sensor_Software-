import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import 'package:my_app/services/telemetry_service.dart';
import 'package:my_app/models/telemetry_model.dart';

class TelemetryDetailScreen extends StatefulWidget {
  final String deviceId;
  const TelemetryDetailScreen({super.key, required this.deviceId});

  @override
  State<TelemetryDetailScreen> createState() => _TelemetryDetailScreenState();
}

class _TelemetryDetailScreenState extends State<TelemetryDetailScreen> {
  final _service = TelemetryService();

  // chart data
  List<FlSpot> _spots = [];
  List<DateTime> _xTimes = [];

  // UI state
  bool _loading = true;
  Object? _error;

  /// '1d' | '7d' | '30d' | '1y'
  String _range = '1d';

  static const _rangeOptions = <String, String>{
    '1d': 'Hôm nay',
    '7d': '7 ngày',
    '30d': '30 ngày',
    '1y': '1 năm',
  };

  @override
  void initState() {
    super.initState();
    _load(); // chỉ load 1 lần khi vào trang
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // lấy & lọc theo device + range
      final List<TelemetryModel> data =
          await _service.fetchTelemetryByDeviceAndRange(
        widget.deviceId,
        range: _range,
      );

      // sort theo thời gian (tăng dần)
      data.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      // build điểm & trục X
      final xTimes = data.map((e) => e.timestamp).toList();
      final spots = List<FlSpot>.generate(
        data.length,
        (i) => FlSpot(i.toDouble(), data[i].temperature.toDouble()),
      );

      // Chỉ setState tại đây
      setState(() {
        _xTimes = xTimes;
        _spots = spots;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e;
      });
    }
  }

  String _formatXLabel(int index) {
    if (index < 0 || index >= _xTimes.length) return '';
    final dt = _xTimes[index].toLocal();
    switch (_range) {
      case '1d':
        return DateFormat('HH:mm').format(dt);
      case '7d':
      case '30d':
        return DateFormat('d/M').format(dt);
      case '1y':
      default:
        return DateFormat('MM/yyyy').format(dt);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // range Y
    final minY = _spots.isEmpty
        ? 0.0
        : (_spots.map((e) => e.y).reduce((a, b) => a < b ? a : b) - 0.5);
    final maxY = _spots.isEmpty
        ? 1.0
        : (_spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 0.5);

    final yRange = (maxY - minY).abs();
    final yInterval = yRange <= 5 ? 1.0 : (yRange / 5).ceilToDouble();

    // range X
    final step = _spots.length <= 8 ? 1 : (_spots.length / 8).ceil();
    final double minX = 0;
    final double maxX = _spots.isEmpty ? 1 : (_spots.length - 1).toDouble();

    return Scaffold(
      appBar: AppBar(title: Text('Nhiệt độ - ${widget.deviceId}')),
      body: RefreshIndicator(
        onRefresh: _load, // chỉ refresh khi kéo xuống
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header kiểu dashboard
                Row(
                  children: [
                    Text('Analysis',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    // chọn range: KHÔNG setState trực tiếp, chỉ đổi biến rồi _load()
                    DropdownButton<String>(
                      value: _range,
                      underline: const SizedBox.shrink(),
                      items: _rangeOptions.entries
                          .map((e) => DropdownMenuItem(
                                value: e.key,
                                child: Text(e.value),
                              ))
                          .toList(),
                      onChanged: (v) async {
                        if (v == null) return;
                        _range = v; // không setState ở đây
                        await _load(); // setState chỉ trong _load()
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Card chứa biểu đồ (style dashboard)
                Container(
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
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _error != null
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Lỗi: $_error'),
                                    const SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: _load,
                                      child: const Text('Thử lại'),
                                    ),
                                  ],
                                ),
                              )
                            : _spots.isEmpty
                                ? const Center(
                                    child: Text('Không có dữ liệu'),
                                  )
                                : LineChart(
                                    LineChartData(
                                      minX: minX,
                                      maxX: maxX,
                                      minY: minY,
                                      maxY: maxY,
                                      lineTouchData: LineTouchData(
                                        enabled: true,
                                        touchTooltipData: LineTouchTooltipData(
                                          getTooltipColor: (touchedSpot) =>
                                              Colors.white.withOpacity(0.9),
                                          tooltipBorderRadius:
                                              BorderRadius.circular(12),
                                          tooltipPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 12, vertical: 8),
                                          tooltipMargin: 12,
                                          getTooltipItems: (touchedSpots) =>
                                              touchedSpots.map((t) {
                                            final idx = t.x.round();
                                            final time = (idx >= 0 &&
                                                    idx < _xTimes.length)
                                                ? _formatXLabel(idx)
                                                : '';
                                            return LineTooltipItem(
                                              '${t.y.toStringAsFixed(1)} °C\n$time',
                                              TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                                color: Colors.grey[800],
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                        handleBuiltInTouches: true,
                                      ),
                                      gridData: FlGridData(
                                        show: true,
                                        drawVerticalLine: true,
                                        drawHorizontalLine: true,
                                        getDrawingHorizontalLine: (v) => FlLine(
                                          color: Colors.grey.withOpacity(0.1),
                                          strokeWidth: 1,
                                          dashArray: [8, 4],
                                        ),
                                        getDrawingVerticalLine: (v) => FlLine(
                                          color: Colors.grey.withOpacity(0.1),
                                          strokeWidth: 1,
                                          dashArray: [8, 4],
                                        ),
                                        verticalInterval: step.toDouble(),
                                        horizontalInterval: yInterval,
                                      ),
                                      titlesData: FlTitlesData(
                                        topTitles: const AxisTitles(
                                            sideTitles:
                                                SideTitles(showTitles: false)),
                                        rightTitles: const AxisTitles(
                                            sideTitles:
                                                SideTitles(showTitles: false)),
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 48,
                                            interval: yInterval,
                                            getTitlesWidget: (value, meta) =>
                                                Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 8),
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
                                            interval: step.toDouble(),
                                            getTitlesWidget: (value, meta) {
                                              final idx = value.round();
                                              if (idx % step != 0)
                                                return const SizedBox.shrink();
                                              if (idx < 0 ||
                                                  idx >= _xTimes.length)
                                                return const SizedBox.shrink();
                                              final label = _formatXLabel(idx);
                                              if (idx == _xTimes.length - 1 &&
                                                  idx - 1 >= 0 &&
                                                  _formatXLabel(idx - 1) ==
                                                      label) {
                                                return const SizedBox.shrink();
                                              }
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 6),
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
                                          color: Colors.grey.withOpacity(0.1),
                                          width: 1,
                                        ),
                                      ),
                                      lineBarsData: [
                                        LineChartBarData(
                                          spots: _spots,
                                          isCurved: true,
                                          barWidth: 4,
                                          color: const Color(0xFF0288D1),
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF0288D1),
                                              Color(0xFF4FC3F7)
                                            ],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ),
                                          isStrokeCapRound: true,
                                          dotData: FlDotData(
                                            show: true,
                                            getDotPainter: (s, p, b, i) =>
                                                FlDotCirclePainter(
                                              radius: 4,
                                              color: Colors.white,
                                              strokeColor:
                                                  const Color(0xFF0288D1),
                                              strokeWidth: 2,
                                            ),
                                          ),
                                          belowBarData: BarAreaData(
                                            show: true,
                                            gradient: LinearGradient(
                                              colors: [
                                                const Color(0xFF0288D1)
                                                    .withOpacity(0.3),
                                                const Color(0xFF4FC3F7)
                                                    .withOpacity(0.1),
                                              ],
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                            ),
                                          ),
                                          shadow: const Shadow(
                                            color: Colors.black12,
                                            blurRadius: 6,
                                            offset: Offset(0, 3),
                                          ),
                                        ),
                                      ],
                                      extraLinesData: ExtraLinesData(),
                                      backgroundColor:
                                          Colors.white.withOpacity(0.05),
                                    ),
                                    duration: const Duration(milliseconds: 600),
                                    curve: Curves.easeInOut,
                                  ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
