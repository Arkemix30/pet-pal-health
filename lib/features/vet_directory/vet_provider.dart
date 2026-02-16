import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/isar_models.dart';
import 'vet_repository.dart';

final vetsStreamProvider = StreamProvider<List<Vet>>((ref) {
  return ref.watch(vetRepositoryProvider).watchVets();
});

final vetManagementProvider = Provider((ref) {
  return ref.watch(vetRepositoryProvider);
});
