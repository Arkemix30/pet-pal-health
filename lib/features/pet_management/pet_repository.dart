import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:isar/isar.dart';
import '../../data/local/isar_models.dart';
import '../../data/local/isar_service.dart';
import '../../core/services/storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final petRepositoryProvider = Provider((ref) {
  final isar = ref.watch(isarProvider);
  final storage = ref.watch(storageServiceProvider);
  return PetRepository(isar, Supabase.instance.client, storage);
});

class PetRepository {
  final Isar _isar;
  final SupabaseClient _supabase;
  final StorageService _storage;

  PetRepository(this._isar, this._supabase, this._storage);

  // Stream of active (non-deleted) pets from local database
  Stream<List<Pet>> watchPets() {
    return _isar.pets
        .filter()
        .isDeletedEqualTo(false)
        .watch(fireImmediately: true);
  }

  Future<void> savePet(Pet pet) async {
    // 1. Save to Local Isar
    await _isar.writeTxn(() async {
      await _isar.pets.put(pet);
    });

    // 2. Sync to Supabase
    _syncPetToRemote(pet);
  }

  Future<void> _syncPetToRemote(Pet pet) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      if (pet.ownerId == null) {
        pet.ownerId = userId;
        await _isar.writeTxn(() async {
          await _isar.pets.put(pet);
        });
      }

      final data = {
        'name': pet.name,
        'species': pet.species,
        'breed': pet.breed,
        'birth_date': pet.birthDate?.toIso8601String(),
        'weight_kg': pet.weightKg,
        'photo_url': pet.photoUrl,
        'owner_id': userId,
        'is_deleted': pet.isDeleted,
      };

      if (pet.supabaseId != null) {
        await _supabase.from('pets').update(data).eq('id', pet.supabaseId!);
      } else {
        final res = await _supabase.from('pets').insert(data).select().single();
        pet.supabaseId = res['id'];
        await _isar.writeTxn(() async {
          await _isar.pets.put(pet);
        });
      }
    } catch (e) {
      print('Sync failed for pet ${pet.name}: $e');
    }
  }

  /// Soft deletes a pet by marking it as deleted.
  Future<void> softDeletePet(Pet pet) async {
    pet.isDeleted = true;

    // 1. Update locally
    await _isar.writeTxn(() async {
      await _isar.pets.put(pet);
    });

    // 2. Sync deletion to remote
    _syncPetToRemote(pet);
  }

  /// Permanent delete (optional, can be used to clean up storage)
  Future<void> deletePetPermanently(
    int localId,
    String? supabaseId,
    String? photoUrl,
  ) async {
    // 1. Delete photo from storage if exists
    if (photoUrl != null) {
      await _storage.deletePhoto(photoUrl);
    }

    // 2. Delete locally
    await _isar.writeTxn(() async {
      await _isar.pets.delete(localId);
    });

    // 3. Delete remotely
    if (supabaseId != null) {
      try {
        await _supabase.from('pets').delete().eq('id', supabaseId);
      } catch (e) {
        print('Remote delete failed: $e');
      }
    }
  }

  /// Finds all pets that haven't been synced to Supabase yet and syncs them.
  Future<void> syncAllUnsynced() async {
    final unsyncedPets = await _isar.pets.filter().supabaseIdIsNull().findAll();
    for (final pet in unsyncedPets) {
      await _syncPetToRemote(pet);
    }
  }

  /// Pulls all pets from Supabase and merges them with the local database.
  Future<void> fetchPetsFromRemote() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final List<dynamic> remoteData = await _supabase
          .from('pets')
          .select()
          .eq('owner_id', userId)
          .eq('is_deleted', false);

      await _isar.writeTxn(() async {
        for (final data in remoteData) {
          final String supabaseId = data['id'];
          final existingPet = await _isar.pets
              .filter()
              .supabaseIdEqualTo(supabaseId)
              .findFirst();

          final pet = existingPet ?? Pet();
          pet.supabaseId = supabaseId;
          pet.ownerId = data['owner_id'];
          pet.name = data['name'];
          pet.species = data['species'];
          pet.breed = data['breed'];
          pet.birthDate = data['birth_date'] != null
              ? DateTime.tryParse(data['birth_date'])
              : null;
          pet.weightKg = (data['weight_kg'] as num?)?.toDouble();
          pet.photoUrl = data['photo_url'];
          pet.isDeleted = data['is_deleted'] ?? false;
          pet.createdAt = data['created_at'] != null
              ? DateTime.tryParse(data['created_at'])
              : DateTime.now();

          await _isar.pets.put(pet);
        }
      });
    } catch (e) {
      print('Failed to pull pets from remote: $e');
    }
  }

  /// Perimeter method to sync everything.
  Future<void> performFullSync() async {
    // 1. Pull new data from remote
    await fetchPetsFromRemote();
    // 2. Push local changes
    await syncAllUnsynced();
  }
}
