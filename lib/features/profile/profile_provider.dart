import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:isar/isar.dart';
import '../../data/local/isar_models.dart';
import '../../data/local/isar_service.dart';
import '../auth/auth_provider.dart';

final profileRepositoryProvider = Provider((ref) {
  final isar = ref.watch(isarProvider);
  final supabase = Supabase.instance.client;
  return ProfileRepository(isar, supabase);
});

final profileProvider = AsyncNotifierProvider<ProfileNotifier, Profile?>(
  ProfileNotifier.new,
);

final userSettingsProvider = AsyncNotifierProvider<UserSettingsNotifier, UserSettings?>(
  UserSettingsNotifier.new,
);

class ProfileRepository {
  final Isar _isar;
  final SupabaseClient _supabase;

  ProfileRepository(this._isar, this._supabase);

  Stream<Profile?> watchProfile() {
    return _isar.profiles.where().watch(fireImmediately: true).map(
          (profiles) => profiles.isEmpty ? null : profiles.first,
        );
  }

  Future<Profile?> getProfile() async {
    final profiles = await _isar.profiles.where().findAll();
    return profiles.isEmpty ? null : profiles.first;
  }

  Future<void> saveProfile(Profile profile) async {
    await _isar.writeTxn(() async {
      await _isar.profiles.put(profile);
    });
    _syncProfileToRemote(profile);
  }

  Future<void> _syncProfileToRemote(Profile profile) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final data = {
        'full_name': profile.fullName,
        'avatar_url': profile.avatarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (profile.supabaseId != null) {
        await _supabase.from('profiles').update(data).eq('id', profile.supabaseId!);
      } else {
        final res = await _supabase
            .from('profiles')
            .insert({...data, 'user_id': userId})
            .select()
            .single();
        profile.supabaseId = res['id'];
        await _isar.writeTxn(() async {
          await _isar.profiles.put(profile);
        });
      }
    } catch (e) {
      print('Sync failed for profile: $e');
    }
  }

  Future<void> syncProfileFromRemote() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final remoteData = await _supabase
          .from('profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (remoteData == null) return;

      final localProfiles = await _isar.profiles.where().findAll();
      Profile? localProfile;

      if (localProfiles.isNotEmpty) {
        localProfile = localProfiles.first;
      } else {
        localProfile = Profile();
      }

      final remoteUpdatedAt = remoteData['updated_at'] != null
          ? DateTime.parse(remoteData['updated_at'])
          : null;

      if (localProfile.updatedAt == null ||
          (remoteUpdatedAt != null && remoteUpdatedAt.isAfter(localProfile.updatedAt!))) {
        localProfile.supabaseId = remoteData['id'];
        localProfile.fullName = remoteData['full_name'];
        localProfile.avatarUrl = remoteData['avatar_url'];
        localProfile.updatedAt = remoteUpdatedAt;

        await _isar.writeTxn(() async {
          await _isar.profiles.put(localProfile!);
        });
      }
    } catch (e) {
      print('Failed to sync profile from remote: $e');
    }
  }

  Future<void> uploadAvatar(String filePath) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final fileName = 'avatars/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _supabase.storage.from('pet-pal-health').upload(fileName, filePath);

      final publicUrl = _supabase.storage.from('pet-pal-health').getPublicUrl(fileName);

      final profile = await getProfile();
      if (profile != null) {
        profile.avatarUrl = publicUrl;
        profile.updatedAt = DateTime.now();
        await saveProfile(profile);
      }
    } catch (e) {
      print('Failed to upload avatar: $e');
      rethrow;
    }
  }
}

class ProfileNotifier extends AsyncNotifier<Profile?> {
  @override
  Future<Profile?> build() async {
    final repo = ref.watch(profileRepositoryProvider);
    return repo.getProfile();
  }

  Future<void> updateProfile({String? fullName, String? avatarUrl}) async {
    final repo = ref.read(profileRepositoryProvider);
    final currentProfile = state.value;

    final profile = currentProfile ?? Profile();
    if (fullName != null) profile.fullName = fullName;
    if (avatarUrl != null) profile.avatarUrl = avatarUrl;
    profile.updatedAt = DateTime.now();

    state = const AsyncLoading();
    await repo.saveProfile(profile);
    state = AsyncData(profile);
  }

  Future<void> uploadAvatar(String filePath) async {
    final repo = ref.read(profileRepositoryProvider);
    state = const AsyncLoading();
    await repo.uploadAvatar(filePath);
    final profile = await repo.getProfile();
    state = AsyncData(profile);
  }

  Future<void> syncFromRemote() async {
    final repo = ref.read(profileRepositoryProvider);
    await repo.syncProfileFromRemote();
    final profile = await repo.getProfile();
    state = AsyncData(profile);
  }
}

class UserSettingsRepository {
  final Isar _isar;
  final SupabaseClient _supabase;

  UserSettingsRepository(this._isar, this._supabase);

  Stream<UserSettings?> watchUserSettings() {
    return _isar.userSettingss.where().watch(fireImmediately: true).map(
          (settings) => settings.isEmpty ? null : settings.first,
        );
  }

  Future<UserSettings?> getUserSettings() async {
    final settings = await _isar.userSettingss.where().findAll();
    return settings.isEmpty ? null : settings.first;
  }

  Future<void> saveUserSettings(UserSettings settings) async {
    settings.updatedAt = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.userSettingss.put(settings);
    });
    _syncSettingsToRemote(settings);
  }

  Future<void> _syncSettingsToRemote(UserSettings settings) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final data = {
        'enable_notifications': settings.enableNotifications,
        'enable_vaccine_reminders': settings.enableVaccineReminders,
        'enable_medication_reminders': settings.enableMedicationReminders,
        'enable_appointment_reminders': settings.enableAppointmentReminders,
        'reminder_hours_before': settings.reminderHoursBefore,
        'updated_at': settings.updatedAt?.toIso8601String(),
      };

      if (settings.supabaseId != null) {
        await _supabase.from('user_settings').update(data).eq('id', settings.supabaseId!);
      } else {
        final res = await _supabase
            .from('user_settings')
            .insert({...data, 'user_id': userId})
            .select()
            .single();
        settings.supabaseId = res['id'];
        await _isar.writeTxn(() async {
          await _isar.userSettingss.put(settings);
        });
      }
    } catch (e) {
      print('Sync failed for user settings: $e');
    }
  }

  Future<void> syncUserSettingsFromRemote() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final remoteData = await _supabase
          .from('user_settings')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (remoteData == null) return;

      final localSettings = await _isar.userSettingss.where().findAll();
      UserSettings? localSetting;

      if (localSettings.isNotEmpty) {
        localSetting = localSettings.first;
      } else {
        localSetting = UserSettings();
      }

      final remoteUpdatedAt = remoteData['updated_at'] != null
          ? DateTime.parse(remoteData['updated_at'])
          : null;

      if (localSetting.updatedAt == null ||
          (remoteUpdatedAt != null && remoteUpdatedAt.isAfter(localSetting.updatedAt!))) {
        localSetting.supabaseId = remoteData['id'];
        localSetting.enableNotifications = remoteData['enable_notifications'] ?? true;
        localSetting.enableVaccineReminders = remoteData['enable_vaccine_reminders'] ?? true;
        localSetting.enableMedicationReminders = remoteData['enable_medication_reminders'] ?? true;
        localSetting.enableAppointmentReminders = remoteData['enable_appointment_reminders'] ?? true;
        localSetting.reminderHoursBefore = remoteData['reminder_hours_before'] ?? 24;
        localSetting.updatedAt = remoteUpdatedAt;

        await _isar.writeTxn(() async {
          await _isar.userSettingss.put(localSetting!);
        });
      }
    } catch (e) {
      print('Failed to sync user settings from remote: $e');
    }
  }
}

class UserSettingsNotifier extends AsyncNotifier<UserSettings?> {
  late final UserSettingsRepository _repo;

  @override
  Future<UserSettings?> build() async {
    _repo = ref.watch(profileRepositoryProvider);
    return _repo.getUserSettings();
  }

  Future<void> updateSettings({
    bool? enableNotifications,
    bool? enableVaccineReminders,
    bool? enableMedicationReminders,
    bool? enableAppointmentReminders,
    int? reminderHoursBefore,
  }) async {
    final currentSettings = state.value ?? UserSettings();

    if (enableNotifications != null) currentSettings.enableNotifications = enableNotifications;
    if (enableVaccineReminders != null) currentSettings.enableVaccineReminders = enableVaccineReminders;
    if (enableMedicationReminders != null) currentSettings.enableMedicationReminders = enableMedicationReminders;
    if (enableAppointmentReminders != null) {
      currentSettings.enableAppointmentReminders = enableAppointmentReminders;
    }
    if (reminderHoursBefore != null) currentSettings.reminderHoursBefore = reminderHoursBefore;

    state = const AsyncLoading();
    await _repo.saveUserSettings(currentSettings);
    state = AsyncData(currentSettings);
  }

  Future<void> syncFromRemote() async {
    await _repo.syncUserSettingsFromRemote();
    final settings = await _repo.getUserSettings();
    state = AsyncData(settings);
  }
}

final logoutProvider = Provider((ref) {
  return () async {
    await Supabase.instance.client.auth.signOut();
  };
});
