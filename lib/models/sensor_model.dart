class SensorModel {
  final int id;
  final String name;
  final double temp;
  final double humidity;
  final bool status;
  final int signal;

  SensorModel({
    required this.id,
    required this.name,
    required this.temp,
    required this.humidity,
    required this.status,
    required this.signal,
  });
}
