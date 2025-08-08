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

  List<FlSpot> _spots = [];
  List<DateTime> _xTimes = [];
  bool _loading = true;
  String _range = '1d'; // Hôm nay mặc định

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      var data = await _service.fetchTelemetryByDeviceAndRange(
        widget.deviceId,
        range: _range,
      );

      // sort theo thời gian
      data.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      // tạo X = index, lưu timestamps để render label
      _xTimes = data.map((e) => e.timestamp).toList();
      _spots = List.generate(
        data.length,
        (i) => FlSpot(i.toDouble(), data[i].temperature.toDouble()),
      );

      setState(() => _loading = false);
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi tải dữ liệu: $e')));
    }
  }

  // Format nhãn trục X theo range
  String _formatXLabel(int index) {
    if (index < 0 || index >= _xTimes.length) return '';
    final dt = _xTimes[index];
    if (_range == '1d') {
      return DateFormat('HH:mm').format(dt.toLocal());
    } else if (_range == '7d' || _range == '30d') {
      return DateFormat('d/M').format(dt.toLocal());
    } else {
      return DateFormat('MM/yyyy').format(dt.toLocal());
    }
  }

  @override
  Widget build(BuildContext context) {
    final minY = _spots.isEmpty
        ? 0.0
        : (_spots.map((e) => e.y).reduce((a, b) => a < b ? a : b) - 0.5);
    final maxY = _spots.isEmpty
        ? 1.0
        : (_spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 0.5);

    // Giảm số nhãn X cho đỡ chồng
    final step = _spots.length <= 8 ? 1 : (_spots.length / 8).ceil();

    return Scaffold(
      appBar: AppBar(title: Text('Nhiệt độ - ${widget.deviceId}')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                const Text('Khoảng thời gian: '),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _range,
                  items: const [
                    DropdownMenuItem(value: '1d', child: Text('Hôm nay')),
                    DropdownMenuItem(value: '7d', child: Text('7 ngày')),
                    DropdownMenuItem(value: '30d', child: Text('30 ngày')),
                    DropdownMenuItem(value: '1y', child: Text('1 năm')),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _range = v);
                    _load();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _spots.isEmpty
                ? const Center(child: Text('Không có dữ liệu'))
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: LineChart(
                      LineChartData(
                        minX: 0,
                        maxX: (_spots.length - 1)
                            .clamp(0, double.infinity)
                            .toDouble(),
                        minY: minY,
                        maxY: maxY,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: true,
                          verticalInterval: step.toDouble(),
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
                              reservedSize: 40,
                              interval: 1, // vì temp ~ 25-40
                              getTitlesWidget: (value, meta) => Text(
                                value.toStringAsFixed(0),
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 34,
                              interval: step.toDouble(),
                              getTitlesWidget: (value, meta) {
                                final idx = value.round();
                                if (idx % step != 0) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    _formatXLabel(idx),
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        clipData: const FlClipData.all(),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _spots,
                            isCurved: true,
                            color: Colors.blue,
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue.withOpacity(.25),
                                  Colors.transparent,
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                            dotData: FlDotData(show: false),
                            barWidth: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
