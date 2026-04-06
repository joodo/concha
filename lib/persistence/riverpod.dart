import 'package:flutter_riverpod/experimental/persist.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod_sqflite/riverpod_sqflite.dart';

part 'riverpod.g.dart';

@Riverpod(keepAlive: true)
Future<Storage<String, String>> storage(Ref ref) async {
  final supportDir = await getApplicationSupportDirectory();
  return JsonSqFliteStorage.open(join(supportDir.path, 'riverpod.db'));
}
