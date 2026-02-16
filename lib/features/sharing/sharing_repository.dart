import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:isar/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/isar_models.dart';
import '../../data/local/isar_service.dart';

final sharingRepositoryProvider = Provider(
  (ref) {
    final isar = ref.watch(isarProvider);
    return SharingRepository(isar, Supabase.instance.client);
  },
);

class SharingRepository {
  final Isar _isar;
  final SupabaseClient _supabase;

  SharingRepository(this._isar, this._supabase);

  Stream<List<PetShare>> watchSharedUsers(String petSupabaseId) {
    return _isar.petShares
        .filter()
        .petSupabaseIdEqualTo(petSupabaseId)
        .statusEqualTo('accepted')
        .watch();
  }

  Future<List<PetShare>> getSharedUsers(String petSupabaseId) async {
    return await _isar.petShares
        .filter()
        .petSupabaseIdEqualTo(petSupabaseId)
        .statusEqualTo('accepted')
        .findAll();
  }

  Future<void> inviteUser({
    required String petSupabaseId,
    required String email,
  }) async {
    final inviterId = _supabase.auth.currentUser?.id;
    if (inviterId == null) return;

    final response = await _supabase.from('pet_invitations').insert({
      'pet_id': petSupabaseId,
      'inviter_id': inviterId,
      'invitee_email': email,
      'token': DateTime.now().millisecondsSinceEpoch.toString(),
      'status': 'pending',
    }).select();

    if (response.isNotEmpty) {
      final invitation = response.first;
      final petShare = PetShare()
        ..petSupabaseId = petSupabaseId
        ..sharedWithEmail = email
        ..status = 'pending'
        ..supabaseId = invitation['id']
        ..accessLevel = 'editor'
        ..createdAt = DateTime.now();

      await _isar.writeTxn(() async {
        await _isar.petShares.put(petShare);
      });
    }
  }

  Future<void> revokeAccess(String shareSupabaseId) async {
    await _isar.writeTxn(() async {
      final share = await _isar.petShares
          .filter()
          .supabaseIdEqualTo(shareSupabaseId)
          .findFirst();
      if (share != null) {
        share.status = 'revoked';
        await _isar.petShares.put(share);
      }
    });

    try {
      await _supabase.from('pet_shares').delete().eq('id', shareSupabaseId);
    } catch (e) {
      print('Failed to revoke remote share: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPetShares(String petSupabaseId) async {
    return await _supabase
        .from('pet_shares')
        .select('*, user_id')
        .eq('pet_id', petSupabaseId);
  }

  Future<void> removeShare(String shareId) async {
    await _supabase.from('pet_shares').delete().eq('id', shareId);
  }

  Future<void> syncSharesFromRemote() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final pets = await _isar.pets.where().findAll();
      final petIds = pets.map((p) => p.supabaseId).whereType<String>().toList();

      if (petIds.isEmpty) return;

      final sharesData = await _supabase
          .from('pet_shares')
          .select()
          .inFilter('pet_id', petIds);

      await _isar.writeTxn(() async {
        for (final data in sharesData) {
          final String supabaseId = data['id'];
          final existing = await _isar.petShares
              .filter()
              .supabaseIdEqualTo(supabaseId)
              .findFirst();

          if (existing == null) {
            final share = PetShare()
              ..supabaseId = supabaseId
              ..petSupabaseId = data['pet_id']
              ..status = 'accepted'
              ..accessLevel = data['access_level']
              ..createdAt = DateTime.tryParse(data['created_at'] ?? '');

            await _isar.petShares.put(share);
          }
        }
      });
    } catch (e) {
      print('Failed to sync shares from remote: $e');
    }
  }
}
