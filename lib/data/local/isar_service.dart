import 'isar_models.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final isarProvider = Provider<Isar>((ref) {
  throw UnimplementedError('Isar has not been initialized');
});

class IsarService {
  static Future<Isar> init() async {
    final dir = await getApplicationDocumentsDirectory();
    return await Isar.open([
      PetSchema,
      ProfileSchema,
      HealthScheduleSchema,
    ], directory: dir.path);
  }
}
