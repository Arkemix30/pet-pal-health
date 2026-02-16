import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/isar_models.dart';
import 'schedule_repository.dart';

final petSchedulesProvider =
    StreamProvider.family<List<HealthSchedule>, String>((ref, petSupabaseId) {
      return ref
          .watch(scheduleRepositoryProvider)
          .watchSchedules(petSupabaseId);
    });

final scheduleManagementProvider = Provider((ref) {
  return ref.watch(scheduleRepositoryProvider);
});
