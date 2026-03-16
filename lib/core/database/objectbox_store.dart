import '../../objectbox.g.dart';

/// Opens the ObjectBox store.
/// Must be called after WidgetsFlutterBinding.ensureInitialized().
Future<Store> openObjectBoxStore() async {
  return openStore();
}
