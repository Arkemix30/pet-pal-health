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
  DateTime? createdAt;
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
}
