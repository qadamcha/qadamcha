import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/network/api_client.dart';

// Auth Feature
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/datasources/auth_local_datasource.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

// Child Feature
import 'features/child/domain/repositories/child_repository.dart';
import 'features/child/data/repositories/child_repository_impl.dart';
import 'features/child/presentation/bloc/child_bloc.dart';

// Content Feature
import 'features/content/domain/repositories/content_repository.dart';
import 'features/content/data/repositories/content_repository_impl.dart';
import 'features/content/data/datasources/content_remote_data_source.dart';
import 'features/content/presentation/bloc/content_bloc.dart';

// Device Feature
import 'features/device/domain/repositories/device_repository.dart';
import 'features/device/data/repositories/device_repository_impl.dart';
import 'features/device/presentation/bloc/device_bloc.dart';

// Subscription Feature
import 'features/subscription/domain/repositories/subscription_repository.dart';
import 'features/subscription/data/repositories/subscription_repository_impl.dart';
import 'features/subscription/presentation/bloc/subscription_bloc.dart';

final sl = GetIt.instance;

Future<void> initializeDependencies() async {
  //=== External ===
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );
  
  //=== Core ===
  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(storage: sl()),
  );
  
  //=== Auth Feature ===
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(
      secureStorage: sl(),
      prefs: sl(),
    ),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
    ),
  );
  sl.registerFactory<AuthBloc>(
    () => AuthBloc(repository: sl()),
  );
  
  //=== Child Feature ===
  sl.registerLazySingleton<ChildRepository>(
    () => ChildRepositoryImpl(apiClient: sl()),
  );
  sl.registerFactory<ChildBloc>(
    () => ChildBloc(repository: sl()),
  );
  
  //=== Content Feature ===
  sl.registerLazySingleton<ContentRemoteDataSource>(
    () => ContentRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<ContentRepository>(
    () => ContentRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerFactory<ContentBloc>(
    () => ContentBloc(repository: sl()),
  );
  
  //=== Device Feature ===
  sl.registerLazySingleton<DeviceRepository>(
    () => DeviceRepositoryImpl(apiClient: sl()),
  );
  sl.registerFactory<DeviceBloc>(
    () => DeviceBloc(repository: sl()),
  );
  
  //=== Subscription Feature ===
  sl.registerLazySingleton<SubscriptionRepository>(
    () => SubscriptionRepositoryImpl(apiClient: sl()),
  );
  sl.registerFactory<SubscriptionBloc>(
    () => SubscriptionBloc(repository: sl()),
  );
}
