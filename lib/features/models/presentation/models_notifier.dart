import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/model_repository.dart';
import '../domain/model.dart';

part 'models_notifier.g.dart';

@riverpod
class ModelsNotifier extends _$ModelsNotifier {
  @override
  Future<List<Model>> build() async {
    return ref.watch(modelRepositoryProvider).getAll();
  }
}
