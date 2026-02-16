import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:isar/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/isar_models.dart';
import '../../data/local/isar_service.dart';

final vetRepositoryProvider = Provider((ref) {
  final isar = ref.watch(isarProvider);
  return VetRepository(isar, Supabase.instance.client);
});

class VetRepository {
  final Isar _isar;
  final SupabaseClient _supabase;

  VetRepository(this._isar, this._supabase);

  Stream<List<Vet>> watchVets() {
    return _isar.vets
        .filter()
        .isDeletedEqualTo(false)
        .watch(fireImmediately: true);
  }

  Future<List<Vet>> getVets() async {
    return await _isar.vets
        .filter()
        .isDeletedEqualTo(false)
        .findAll();
  }

  Future<void> saveVet(Vet vet) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null && vet.ownerId == null) {
      vet.ownerId = userId;
    }

    await _isar.writeTxn(() async {
      await _isar.vets.put(vet);
    });

    await _syncVetToRemote(vet);
  }

  Future<void> _syncVetToRemote(Vet vet) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      if (vet.ownerId == null) {
        vet.ownerId = userId;
        await _isar.writeTxn(() async {
          await _isar.vets.put(vet);
        });
      }

      final data = {
        'owner_id': userId,
        'name': vet.name,
        'phone': vet.phone,
        'address': vet.address,
        'notes': vet.notes,
        'is_deleted': vet.isDeleted,
      };

      if (vet.supabaseId != null) {
        await _supabase.from('vets').update(data).eq('id', vet.supabaseId!);
      } else {
        final res = await _supabase.from('vets').insert(data).select().single();
        vet.supabaseId = res['id'];
        await _isar.writeTxn(() async {
          await _isar.vets.put(vet);
        });
      }
    } catch (e) {
      print('Vet sync failed: $e');
    }
  }

  Future<void> deleteVet(int localId, String? supabaseId) async {
    await _isar.writeTxn(() async {
      await _isar.vets.delete(localId);
    });

    if (supabaseId != null) {
      try {
        await _supabase.from('vets').delete().eq('id', supabaseId);
      } catch (e) {
        print('Remote vet delete failed: $e');
      }
    }
  }

  Future<void> softDeleteVet(Vet vet) async {
    vet.isDeleted = true;

    await _isar.writeTxn(() async {
      await _isar.vets.put(vet);
    });

    await _syncVetToRemote(vet);
  }

  Future<void> syncVetsFromRemote() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final List<dynamic> remoteData = await _supabase
          .from('vets')
          .select()
          .eq('owner_id', userId)
          .eq('is_deleted', false);

      await _isar.writeTxn(() async {
        for (final data in remoteData) {
          final String supabaseId = data['id'];
          final existingVet = await _isar.vets
              .filter()
              .supabaseIdEqualTo(supabaseId)
              .findFirst();

          final vet = existingVet ?? Vet();
          vet.supabaseId = supabaseId;
          vet.ownerId = data['owner_id'];
          vet.name = data['name'];
          vet.phone = data['phone'];
          vet.address = data['address'];
          vet.notes = data['notes'];
          vet.isDeleted = data['is_deleted'] ?? false;
          vet.createdAt = data['created_at'] != null
              ? DateTime.tryParse(data['created_at'])
              : DateTime.now();

          await _isar.vets.put(vet);
        }
      });
    } catch (e) {
      print('Failed to pull vets from remote: $e');
    }
  }
}
