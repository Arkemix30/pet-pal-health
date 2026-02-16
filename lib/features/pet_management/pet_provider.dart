import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/isar_models.dart';
import 'pet_repository.dart';

final petsStreamProvider = StreamProvider<List<Pet>>((ref) {
  return ref.watch(petRepositoryProvider).watchPets();
});

final petManagementProvider = Provider((ref) {
  return ref.watch(petRepositoryProvider);
});
