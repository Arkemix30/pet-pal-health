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

    // 2. Schedule recurring local notification
    await _notificationService.scheduleRecurringNotification(
      baseId: schedule.id,
      title: "Pet Care Reminder: ${schedule.title}",
      body: "Time for your pet's ${schedule.type}!",
      startDate: schedule.startDate,
      frequency: schedule.frequency ?? 'one-time',
    );

    // 3. Sync to remote
    await _syncScheduleToRemote(schedule);
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
        final res = await _supabase
            .from('health_schedules')
            .update(data)
            .eq('id', schedule.supabaseId!)
            .select()
            .single();
        schedule.updatedAt = DateTime.tryParse(res['updated_at'] ?? '');
      } else {
        final res = await _supabase
            .from('health_schedules')
            .insert(data)
            .select()
            .single();
        schedule.supabaseId = res['id'];
        schedule.updatedAt = DateTime.tryParse(res['updated_at'] ?? '');
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

    // 2. Cancel all recurring notifications
    await _notificationService.cancelRecurringNotifications(schedule.id);

    // 3. Sync to remote
    await _syncScheduleToRemote(schedule);
  }

  Future<void> deleteSchedule(int localId, String? supabaseId) async {
    // 1. Cancel all recurring notifications
    await _notificationService.cancelRecurringNotifications(localId);

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

  /// Finds all schedules that haven't been synced to Supabase yet and syncs them.
  Future<void> syncAllUnsynced() async {
    final unsynced = await _isar.healthSchedules
        .filter()
        .supabaseIdIsNull()
        .findAll();
    for (final schedule in unsynced) {
      await _syncScheduleToRemote(schedule);
    }
  }

  /// Pulls all schedules from Supabase for current users' pets and merges them locally.
  Future<void> fetchSchedulesFromRemote() async {
    try {
      // 1. Get all local pet supabase IDs to filter the pull
      final localPets = await _isar.pets.where().findAll();
      final petIds = localPets
          .map((p) => p.supabaseId)
          .whereType<String>()
          .toList();

      if (petIds.isEmpty) return;

      final List<dynamic> remoteData = await _supabase
          .from('health_schedules')
          .select()
          .inFilter('pet_id', petIds);

      await _isar.writeTxn(() async {
        for (final data in remoteData) {
          final String supabaseId = data['id'];
          final existing = await _isar.healthSchedules
              .filter()
              .supabaseIdEqualTo(supabaseId)
              .findFirst();

          final schedule = existing ?? HealthSchedule();
          schedule.supabaseId = supabaseId;
          schedule.petSupabaseId = data['pet_id'];
          schedule.title = data['title'];
          schedule.type = data['type'];
          schedule.startDate = DateTime.parse(data['start_date']);
          schedule.frequency = data['frequency'];
          schedule.notes = data['notes'];
          schedule.isCompleted = data['is_completed'] ?? false;
          schedule.completedAt = data['completed_at'] != null
              ? DateTime.tryParse(data['completed_at'])
              : null;
          schedule.createdAt = data['created_at'] != null
              ? DateTime.tryParse(data['created_at'])
              : DateTime.now();
          schedule.updatedAt = data['updated_at'] != null
              ? DateTime.tryParse(data['updated_at'])
              : null;

          await _isar.healthSchedules.put(schedule);

          // Update/Re-schedule recurring notification if not completed
          if (!schedule.isCompleted) {
            await _notificationService.scheduleRecurringNotification(
              baseId: schedule.id,
              title: "Pet Care Reminder: ${schedule.title}",
              body: "Time for your pet's ${schedule.type}!",
              startDate: schedule.startDate,
              frequency: schedule.frequency ?? 'one-time',
            );
          }
        }
      });
    } catch (e) {
      print('Failed to pull schedules: $e');
    }
  }
}
