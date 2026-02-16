import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/isar_models.dart';
import 'pet_repository.dart';

final petsStreamProvider = StreamProvider<List<Pet>>((ref) async* {
  final repo = ref.watch(petRepositoryProvider);

  // Attempt initial sync (fire and forget to not block UI, or await if critical)
  // For better UX, we yield local data immediately, then sync in background
  try {
    await repo.performFullSync();
  } catch (e) {
    print('Initial sync failed: $e');
  }

  yield* repo.watchPets();
});

final petManagementProvider = Provider((ref) {
  return ref.watch(petRepositoryProvider);
});

final singlePetStreamProvider = StreamProvider.family<Pet?, int>((ref, id) {
  final repo = ref.watch(petRepositoryProvider);
  return repo.watchPet(id);
});
