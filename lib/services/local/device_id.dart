import 'dart:math';

import 'local_store.dart';

/// Id aleatorio del teléfono. Lo usan el asistente (20 preguntas al día) y las
/// encuestas (una vez por encuesta). No identifica a la persona: el servidor
/// solo guarda su hash.
const deviceIdKey = 'jcv_dispositivo';

final uuidPattern = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');

/// Lee el id guardado o crea uno. Si no se puede guardar, dura lo que la sesión.
Future<String> deviceId(LocalStore store) async {
  final stored = await store.read(deviceIdKey);
  if (stored != null && uuidPattern.hasMatch(stored)) return stored;
  final id = newDeviceId();
  await store.write(deviceIdKey, id);
  return id;
}

/// UUID v4 con Random.secure. ponytail: no vale un paquete por 6 líneas.
String newDeviceId([Random? random]) {
  final r = random ?? Random.secure();
  final bytes = List<int>.generate(16, (_) => r.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // versión 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // variante RFC 4122
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-'
      '${hex.substring(16, 20)}-${hex.substring(20)}';
}
