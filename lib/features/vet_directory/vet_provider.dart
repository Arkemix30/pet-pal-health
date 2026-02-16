import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/isar_models.dart';
import 'vet_repository.dart';

final vetsStreamProvider = StreamProvider<List<Vet>>((ref) async* {
  final repo = ref.watch(vetRepositoryProvider);

  // 1. Attempt to sync from Supabase first
  try {
    await repo.syncVetsFromRemote();
  } catch (e) {
    print('Initial vet sync failed: $e');
  }

  // 2. Yield local stream
  yield* repo.watchVets();
});

final vetManagementProvider = Provider((ref) {
  return ref.watch(vetRepositoryProvider);
});
