import 'package:flutter_riverpod/experimental/persist.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod_sqflite/riverpod_sqflite.dart';

import 'init.dart';

part 'riverpod.g.dart';

@riverpod
Future<Storage<String, String>> storage(Ref ref) async {
  return JsonSqFliteStorage.open(riverpodDbPath);
}
