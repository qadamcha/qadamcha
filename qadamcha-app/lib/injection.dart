import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qadamcha_app/core/network/api_client.dart';

// Auth Feature
import 'package:qadamcha_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:qadamcha_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:qadamcha_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:qadamcha_app/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:qadamcha_app/features/auth/presentation/bloc/auth_bloc.dart';

// Child Feature
import 'package:qadamcha_app/features/child/domain/repositories/child_repository.dart';
import 'package:qadamcha_app/features/child/data/repositories/child_repository_impl.dart';
import 'package:qadamcha_app/features/child/presentation/bloc/child_bloc.dart';

// Content Feature
import 'package:qadamcha_app/features/content/domain/repositories/content_repository.dart';
import 'package:qadamcha_app/features/content/data/repositories/content_repository_impl.dart';
import 'package:qadamcha_app/features/content/data/datasources/content_remote_data_source.dart';
import 'package:qadamcha_app/features/content/presentation/bloc/content_bloc.dart';

// Device Feature
import 'package:qadamcha_app/features/device/domain/repositories/device_repository.dart';
import 'package:qadamcha_app/features/device/data/repositories/device_repository_impl.dart';
import 'package:qadamcha_app/features/device/presentation/bloc/device_bloc.dart';

// Subscription Feature
import 'package:qadamcha_app/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:qadamcha_app/features/subscription/data/repositories/subscription_repository_impl.dart';
import 'package:qadamcha_app/features/subscription/presentation/bloc/subscription_bloc.dart';

// AI Chat Feature
import 'package:qadamcha_app/features/ai_chat/domain/repositories/ai_chat_repository.dart';
import 'package:qadamcha_app/features/ai_chat/data/repositories/ai_chat_repository_impl.dart';
import 'package:qadamcha_app/features/ai_chat/data/datasources/ai_chat_remote_datasource.dart';
import 'package:qadamcha_app/features/ai_chat/data/datasources/chat_local_datasource.dart';
import 'package:qadamcha_app/features/ai_chat/presentation/bloc/ai_chat_bloc.dart';

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
    () => AuthBloc(repository: sl(), localDataSource: sl()),
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

  //=== AI Chat Feature ===
  sl.registerLazySingleton<AiChatRemoteDataSource>(
    () => AiChatRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<ChatLocalDataSource>(
    () => ChatLocalDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<AiChatRepository>(
    () => AiChatRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<AiChatBloc>(
    () => AiChatBloc(repository: sl(), localDataSource: sl()),
  );
}
