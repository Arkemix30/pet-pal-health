import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sharingRepositoryProvider = Provider(
  (ref) => SharingRepository(Supabase.instance.client),
);

class SharingRepository {
  final SupabaseClient _supabase;
  SharingRepository(this._supabase);

  // Send an invitation to another user by email
  Future<void> inviteUser({
    required String petSupabaseId,
    required String email,
  }) async {
    final inviterId = _supabase.auth.currentUser?.id;
    if (inviterId == null) return;

    // In a real app, this might trigger an Edge Function to send an email.
    // For now, we'll insert into a 'pet_invitations' table.
    await _supabase.from('pet_invitations').insert({
      'pet_id': petSupabaseId,
      'inviter_id': inviterId,
      'invitee_email': email,
      'token': DateTime.now().millisecondsSinceEpoch.toString(), // Dummy token
      'status': 'pending',
    });
  }

  // Get current shares for a pet
  Future<List<Map<String, dynamic>>> getPetShares(String petSupabaseId) async {
    // This assumes we have a 'pet_shares' table linked with profiles or emails
    return await _supabase
        .from('pet_shares')
        .select('*, user_id')
        .eq('pet_id', petSupabaseId);
  }

  // Remove a share
  Future<void> removeShare(String shareId) async {
    await _supabase.from('pet_shares').delete().eq('id', shareId);
  }
}
