import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

/// Genera y persiste un identificador estable por instalación, usado como
/// `dispositivo_id` en POST /pacientes/sync y POST /atenciones/sync.
class DeviceIdService {
  static const _key = 'device_id';

  final _storage = const FlutterSecureStorage();
  String? _cached;

  Future<String> getDeviceId() async {
    if (_cached != null) return _cached!;
    var id = await _storage.read(key: _key);
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      await _storage.write(key: _key, value: id);
    }
    _cached = id;
    return id;
  }
}
