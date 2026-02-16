import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:isar/isar.dart';
import '../../data/local/isar_models.dart';
import '../../data/local/isar_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final petRepositoryProvider = Provider((ref) {
  final isar = ref.watch(isarProvider);
  return PetRepository(isar, Supabase.instance.client);
});

class PetRepository {
  final Isar _isar;
  final SupabaseClient _supabase;

  PetRepository(this._isar, this._supabase);

  // Stream of all pets from local database
  Stream<List<Pet>> watchPets() {
    return _isar.pets.where().watch(fireImmediately: true);
  }

  Future<void> savePet(Pet pet) async {
    // 1. Save to Local Isar
    await _isar.writeTxn(() async {
      await _isar.pets.put(pet);
    });

    // 2. Sync to Supabase (Optimistic UI approach - sync in background)
    _syncPetToRemote(pet);
  }

  Future<void> _syncPetToRemote(Pet pet) async {
    try {
      final data = {
        'name': pet.name,
        'species': pet.species,
        'breed': pet.breed,
        'birth_date': pet.birthDate?.toIso8601String(),
        'weight_kg': pet.weightKg,
        'photo_url': pet.photoUrl,
        'owner_id': _supabase.auth.currentUser?.id,
      };

      if (pet.supabaseId != null) {
        await _supabase.from('pets').update(data).eq('id', pet.supabaseId!);
      } else {
        final res = await _supabase.from('pets').insert(data).select().single();
        // Update local with the new Supabase ID
        pet.supabaseId = res['id'];
        await _isar.writeTxn(() async {
          await _isar.pets.put(pet);
        });
      }
    } catch (e) {
      // In Task C-003 we will implement a proper retry queue
      print('Sync failed for pet ${pet.name}: $e');
    }
  }

  Future<void> deletePet(int localId, String? supabaseId) async {
    await _isar.writeTxn(() async {
      await _isar.pets.delete(localId);
    });

    if (supabaseId != null) {
      try {
        await _supabase.from('pets').delete().eq('id', supabaseId);
      } catch (e) {
        print('Remote delete failed: $e');
      }
    }
  }
}
