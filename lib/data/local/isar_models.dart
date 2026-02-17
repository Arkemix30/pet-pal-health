import 'package:isar/isar.dart';

part 'isar_models.g.dart';

@collection
class Profile {
  Id id = Isar.autoIncrement;

  @Index()
  String? supabaseId;

  String? fullName;
  String? avatarUrl;
  DateTime? updatedAt;
}

@collection
class Pet {
  Id id = Isar.autoIncrement;

  @Index()
  String? supabaseId;

  String? ownerId;

  @Index()
  late String name;

  late String species;
  String? breed;
  DateTime? birthDate;
  double? weightKg;
  String? photoUrl;
  bool isDeleted = false;
  bool isSynced = true;
  DateTime? createdAt;
  DateTime? updatedAt;
}

@collection
class HealthSchedule {
  Id id = Isar.autoIncrement;

  @Index()
  String? supabaseId;

  String? petSupabaseId;

  late String title;
  late String type; // 'vaccine', 'medication', 'deworming', 'appointment'

  @Index()
  late DateTime startDate;

  String? frequency; // 'one-time', 'daily', 'weekly', 'monthly'
  String? notes;
  bool isCompleted = false;
  DateTime? completedAt;
  DateTime? createdAt;
  DateTime? updatedAt;
}

@collection
class PetShare {
  Id id = Isar.autoIncrement;

  @Index()
  String? supabaseId;

  @Index()
  String? petSupabaseId;

  String? sharedWithEmail;
  String? accessLevel; // 'editor', 'viewer'
  String? status; // 'pending', 'accepted', 'revoked'
  DateTime? createdAt;
}

@collection
class Vet {
  Id id = Isar.autoIncrement;

  @Index()
  String? supabaseId;

  String? ownerId;

  late String name;
  String? phone;
  String? address;
  String? notes;

  // New UI-related fields
  double? rating;
  int? ratingCount;
  double? distance;
  bool isFavorite = false;
  String? specialty;
  String? imageUrl;

  bool isDeleted = false;
  DateTime? createdAt;
  DateTime? updatedAt;
}

@collection
class UserSettings {
  Id id = Isar.autoIncrement;

  @Index()
  String? supabaseId;

  String? ownerId;

  bool enableNotifications = true;
  bool enableVaccineReminders = true;
  bool enableMedicationReminders = true;
  bool enableAppointmentReminders = true;
  int reminderHoursBefore = 24;
  DateTime? updatedAt;
}
