import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:self_dojo_mobile/core/config/app_router.dart';
import 'package:self_dojo_mobile/core/theme/app_theme.dart';
import 'package:self_dojo_mobile/data/repositories/academy_repository.dart';
import 'package:self_dojo_mobile/data/repositories/auth_repository.dart';
import 'package:self_dojo_mobile/data/repositories/profile_repository.dart';
import 'package:self_dojo_mobile/data/services/academy_service.dart';
import 'package:self_dojo_mobile/data/services/firebase_auth_service.dart';
import 'package:self_dojo_mobile/data/services/firestore_service.dart';
import 'package:self_dojo_mobile/data/services/storage_service.dart';
import 'package:self_dojo_mobile/firebase_options.dart';
import 'package:self_dojo_mobile/ui/features/auth/view_models/auth_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configura orientação e barra de status
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Inicializa Firebase com as opções da plataforma
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const SelfDojoApp());
}

/// Aplicação principal
class SelfDojoApp extends StatelessWidget {
  const SelfDojoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Services
        Provider<FirebaseAuthService>(
          create: (_) => FirebaseAuthService(),
        ),
        Provider<FirestoreService>(
          create: (_) => FirestoreService(),
        ),
        Provider<StorageService>(
          create: (_) => StorageService(),
        ),
        Provider<AcademyService>(
          create: (_) => AcademyService(),
        ),

        // Repositories
        Provider<AuthRepository>(
          create: (ctx) => AuthRepositoryImpl(
            authService: ctx.read<FirebaseAuthService>(),
          ),
        ),
        Provider<ProfileRepository>(
          create: (ctx) => ProfileRepositoryImpl(
            firestoreService: ctx.read<FirestoreService>(),
            storageService: ctx.read<StorageService>(),
          ),
        ),
        Provider<AcademyRepository>(
          create: (ctx) => AcademyRepositoryImpl(
            academyService: ctx.read<AcademyService>(),
          ),
        ),

        // ViewModels Globais
        ChangeNotifierProvider<AuthViewModel>(
          create: (ctx) => AuthViewModel(
            authRepository: ctx.read<AuthRepository>(),
          ),
        ),

        // Router
        Provider<AppRouter>(
          create: (ctx) => AppRouter(
            authViewModel: ctx.read<AuthViewModel>(),
          ),
        ),
      ],
      child: const _AppContent(),
    );
  }
}

class _AppContent extends StatelessWidget {
  const _AppContent();

  @override
  Widget build(BuildContext context) {
    final router = context.read<AppRouter>().router;

    return MaterialApp.router(
      title: 'Self Dojo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
