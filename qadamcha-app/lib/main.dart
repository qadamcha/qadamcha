import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/theme/app_theme.dart';
import 'core/services/local_monitoring_service.dart';
import 'injection.dart' as di;

// BLoCs
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/child/presentation/bloc/child_bloc.dart';
import 'features/content/presentation/bloc/content_bloc.dart';
import 'features/device/presentation/bloc/device_bloc.dart';
import 'features/subscription/presentation/bloc/subscription_bloc.dart';

// Pages
import 'features/auth/presentation/pages/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize dependencies
  await di.initializeDependencies();
  
  // Local monitoring service boshlash
  await LocalMonitoringService.instance.initialize();
  
  // Set system UI
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  
  // Lock orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const QadamchaApp());
}

class QadamchaApp extends StatelessWidget {
  const QadamchaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>(
              create: (_) => di.sl<AuthBloc>(),
            ),
            BlocProvider<ChildBloc>(
              create: (_) => di.sl<ChildBloc>(),
            ),
            BlocProvider<ContentBloc>(
              create: (_) => di.sl<ContentBloc>(),
            ),
            BlocProvider<DeviceBloc>(
              create: (_) => di.sl<DeviceBloc>(),
            ),
            BlocProvider<SubscriptionBloc>(
              create: (_) => di.sl<SubscriptionBloc>(),
            ),
          ],
          child: MaterialApp(
            title: 'Qadamcha',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            home: const SplashPage(),
          ),
        );
      },
    );
  }
}
