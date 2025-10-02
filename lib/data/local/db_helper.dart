import 'package:hive_ce_flutter/hive_flutter.dart';

class HiveHelper {
  static Future<void> initHive(List<TypeAdapter> adapters) async {
    await Hive.initFlutter();

    // Register all adapters
    for (var adapter in adapters) {
      Hive.registerAdapter(adapter);
    }
  }

  static Future<Box<T>> openBox<T>(String boxName) async {
    return await Hive.openBox<T>(boxName);
  }

  static Future<int> insert<T>(String boxName, T data) async {
    final box = await openBox<T>(boxName);
    return await box.add(data);
  }

  static Future<void> update<T>(String boxName, int key, T data) async {
    final box = await openBox<T>(boxName);
    await box.put(key, data);
  }

  static Future<void> delete<T>(String boxName, int key) async {
    final box = await openBox<T>(boxName);
    await box.delete(key);
  }

  static Future<T?> fetchOne<T>(String boxName, int key) async {
    final box = await openBox<T>(boxName);
    return box.get(key);
  }

  static Future<List<T>> fetchAll<T>(String boxName) async {
    final box = await openBox<T>(boxName);
    return box.values.toList();
  }

  static Future<void> closeBox<T>(String boxName) async {
    final box = await openBox<T>(boxName);
    await box.close();
  }
}
