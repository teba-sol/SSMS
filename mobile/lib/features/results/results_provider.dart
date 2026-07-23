import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/result_model.dart';
import 'results_repository.dart';

final resultsRepositoryProvider =
    Provider<ResultsRepository>((ref) => ResultsRepository());

final studentResultsProvider =
    FutureProvider.family<List<Result>, String>((ref, studentId) async {
  final repo = ref.read(resultsRepositoryProvider);
  final result = await repo.getByStudent(studentId);
  return result.fold((e) => throw Exception(e), (v) => v);
});

final assignmentResultsProvider =
    FutureProvider.family<List<Result>, String>((ref, assignmentId) async {
  final repo = ref.read(resultsRepositoryProvider);
  final result = await repo.getByAssignment(assignmentId);
  return result.fold((e) => throw Exception(e), (v) => v);
});

class ResultsNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> create(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    final repo = ref.read(resultsRepositoryProvider);
    final result = await repo.create(data);
    result.fold(
      (e) => state = AsyncValue.error(e, StackTrace.current),
      (_) => state = const AsyncValue.data(null),
    );
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    final repo = ref.read(resultsRepositoryProvider);
    final result = await repo.update(id, data);
    result.fold(
      (e) => state = AsyncValue.error(e, StackTrace.current),
      (_) => state = const AsyncValue.data(null),
    );
  }

  Future<void> delete(String id) async {
    state = const AsyncValue.loading();
    final repo = ref.read(resultsRepositoryProvider);
    final result = await repo.delete(id);
    result.fold(
      (e) => state = AsyncValue.error(e, StackTrace.current),
      (_) => state = const AsyncValue.data(null),
    );
  }
}

final resultsNotifierProvider =
    NotifierProvider<ResultsNotifier, AsyncValue<void>>(ResultsNotifier.new);
