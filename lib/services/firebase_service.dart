import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class FirebaseChangeListener {
  final String databaseUrl;
  final String path; // ví dụ 'telemrtry_updates'
  DatabaseReference? _ref;
  StreamSubscription<DatabaseEvent>? _sub;

  FirebaseChangeListener({
    this.databaseUrl =
        'https://temperature-sensor-software-default-rtdb.firebaseio.com',
    this.path = 'telemrtry_updates',
  });

  Future<void> start({
    required void Function() onChanged,
    Duration debounce = const Duration(seconds: 5),
  }) async {
    final db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: databaseUrl,
    );
    _ref = db.ref(path);

    Timer? _timer;
    _sub = _ref!.onValue.listen((_) {
      // debounce: gom nhiều thay đổi, chỉ gọi 1 lần
      _timer?.cancel();
      _timer = Timer(debounce, () {
        onChanged();
      });
    });
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }
}
