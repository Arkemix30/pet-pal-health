import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

final storageServiceProvider = Provider(
  (ref) => StorageService(Supabase.instance.client),
);

class StorageService {
  final SupabaseClient _supabase;
  StorageService(this._supabase);

  static const String petProfilesBucket = 'pet-profiles';

  /// Uploads a pet profile image to Supabase Storage.
  /// Returns the public URL of the uploaded image.
  Future<String?> uploadPetPhoto(File file, String userId) async {
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}${p.extension(file.path)}';
      final filePath = '$userId/$fileName';

      await _supabase.storage
          .from(petProfilesBucket)
          .upload(
            filePath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      final String publicUrl = _supabase.storage
          .from(petProfilesBucket)
          .getPublicUrl(filePath);
      return publicUrl;
    } catch (e) {
      print('Error uploading pet photo: $e');
      rethrow;
    }
  }

  /// Deletes an image from storage using its public URL
  Future<void> deletePhoto(String url) async {
    try {
      final uri = Uri.parse(url);
      final folders = uri.pathSegments;
      // Typical URL: .../storage/v1/object/public/pet-profiles/userId/filename.jpg
      // pathSegments would be [..., 'pet-profiles', 'userId', 'filename.jpg']
      final bucketIndex = folders.indexOf(petProfilesBucket);
      if (bucketIndex != -1 && bucketIndex + 1 < folders.length) {
        final filePath = folders.sublist(bucketIndex + 1).join('/');
        await _supabase.storage.from(petProfilesBucket).remove([filePath]);
      }
    } catch (e) {
      print('Error deleting photo: $e');
    }
  }
}
