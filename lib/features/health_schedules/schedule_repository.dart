import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:isar/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/isar_models.dart';
import '../../data/local/isar_service.dart';
import '../../core/services/notification_service.dart';

final scheduleRepositoryProvider = Provider((ref) {
  final isar = ref.watch(isarProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  return ScheduleRepository(
    isar,
    Supabase.instance.client,
    notificationService,
  );
});

class ScheduleRepository {
  final Isar _isar;
  final SupabaseClient _supabase;
  final NotificationService _notificationService;

  ScheduleRepository(this._isar, this._supabase, this._notificationService);

  // Watch all schedules for a specific pet
  Stream<List<HealthSchedule>> watchSchedules(String petSupabaseId) {
    return _isar.healthSchedules
        .filter()
        .petSupabaseIdEqualTo(petSupabaseId)
        .sortByStartDate()
        .watch(fireImmediately: true);
  }

  // Watch all schedules across all pets
  Stream<List<HealthSchedule>> watchAllSchedules() {
    return _isar.healthSchedules.where().sortByStartDate().watch(
      fireImmediately: true,
    );
  }

  Future<void> saveSchedule(HealthSchedule schedule) async {
    // 1. Save locally
    await _isar.writeTxn(() async {
      await _isar.healthSchedules.put(schedule);
    });

    // 2. Schedule local notification
    await _notificationService.scheduleNotification(
      id: schedule.id,
      title: "Pet Care Reminder: ${schedule.title}",
      body: "Time for your pet's ${schedule.type}!",
      scheduledDate: schedule.startDate,
    );

    // 3. Sync to remote
    _syncScheduleToRemote(schedule);
  }

  Future<void> _syncScheduleToRemote(HealthSchedule schedule) async {
    try {
      if (schedule.petSupabaseId == null) return;

      final data = {
        'pet_id': schedule.petSupabaseId,
        'title': schedule.title,
        'type': schedule.type,
        'start_date': schedule.startDate.toIso8601String(),
        'frequency': schedule.frequency,
        'notes': schedule.notes,
        'is_completed': schedule.isCompleted,
        'completed_at': schedule.completedAt?.toIso8601String(),
      };

      if (schedule.supabaseId != null) {
        await _supabase
            .from('health_schedules')
            .update(data)
            .eq('id', schedule.supabaseId!);
      } else {
        final res = await _supabase
            .from('health_schedules')
            .insert(data)
            .select()
            .single();
        schedule.supabaseId = res['id'];
        await _isar.writeTxn(() async {
          await _isar.healthSchedules.put(schedule);
        });
      }
    } catch (e) {
      print('Schedule sync failed: $e');
    }
  }

  Future<void> completeSchedule(HealthSchedule schedule) async {
    schedule.isCompleted = true;
    schedule.completedAt = DateTime.now();

    // 1. Update locally
    await _isar.writeTxn(() async {
      await _isar.healthSchedules.put(schedule);
    });

    // 2. Cancel existing notification if any
    await _notificationService.cancelNotification(schedule.id);

    // 3. Sync to remote
    _syncScheduleToRemote(schedule);
  }

  Future<void> deleteSchedule(int localId, String? supabaseId) async {
    // 1. Cancel notification
    await _notificationService.cancelNotification(localId);

    // 2. Delete locally
    await _isar.writeTxn(() async {
      await _isar.healthSchedules.delete(localId);
    });

    // 3. Delete remotely
    if (supabaseId != null) {
      try {
        await _supabase.from('health_schedules').delete().eq('id', supabaseId);
      } catch (e) {
        print('Remote schedule delete failed: $e');
      }
    }
  }
}
