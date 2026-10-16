import 'package:get_it/get_it.dart';

/// Dependency Injection locator sử dụng get_it
final sl = GetIt.instance;

Future<void> init() async {
  // TODO: Đăng ký BLoC, Repository, Datasource sau khi build xong các feature
  // Ví dụ:
  // sl.registerFactory(() => HomeBloc(homeRepository: sl()));
}