import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:self_dojo_mobile/core/config/app_router.dart';
import 'package:self_dojo_mobile/core/config/supabase_config.dart';
import 'package:self_dojo_mobile/core/theme/app_theme.dart';
import 'package:self_dojo_mobile/data/repositories/academy_repository.dart';
import 'package:self_dojo_mobile/data/repositories/academy_repository_supabase.dart';
import 'package:self_dojo_mobile/data/repositories/auth_repository.dart';
import 'package:self_dojo_mobile/data/repositories/auth_repository_backend.dart';
import 'package:self_dojo_mobile/data/repositories/profile_repository.dart';
import 'package:self_dojo_mobile/data/repositories/profile_repository_hybrid.dart';
import 'package:self_dojo_mobile/data/repositories/profile_repository_supabase.dart';
import 'package:self_dojo_mobile/data/repositories/students_repository.dart';
import 'package:self_dojo_mobile/data/repositories/students_repository_hybrid.dart';
import 'package:self_dojo_mobile/data/repositories/students_repository_supabase.dart';
import 'package:self_dojo_mobile/data/repositories/academy_search_repository.dart';
import 'package:self_dojo_mobile/data/repositories/academy_search_repository_supabase.dart';
import 'package:self_dojo_mobile/data/repositories/class_schedule_repository.dart';
import 'package:self_dojo_mobile/data/repositories/class_schedule_repository_hybrid.dart';
import 'package:self_dojo_mobile/data/repositories/class_schedule_repository_supabase.dart';
import 'package:self_dojo_mobile/data/services/backend_api_client.dart';
import 'package:self_dojo_mobile/data/services/auth_session_store.dart';
import 'package:self_dojo_mobile/data/services/backend_auth_service.dart';
import 'package:self_dojo_mobile/data/services/profile_service.dart';
import 'package:self_dojo_mobile/data/services/supabase_service.dart';
import 'package:self_dojo_mobile/ui/features/auth/view_models/auth_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carrega variáveis locais de ambiente (opcional).
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}

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

  // Inicializa Supabase (para Database e Storage)
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  final sessionStore = AuthSessionStore();
  await sessionStore.initialize();

  runApp(SelfDojoApp(sessionStore: sessionStore));
}

/// Aplicação principal
class SelfDojoApp extends StatelessWidget {
  const SelfDojoApp({
    super.key,
    required this.sessionStore,
  });

  final AuthSessionStore sessionStore;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Services
        Provider<AuthSessionStore>.value(
          value: sessionStore,
        ),
        Provider<SupabaseService>(
          create: (_) => SupabaseService(),
        ),
        Provider<BackendApiClient>(
          create: (ctx) => BackendApiClient(
            tokenProvider: () => ctx.read<AuthSessionStore>().token,
            onUnauthorized: () => ctx.read<AuthSessionStore>().clear(),
          ),
        ),
        Provider<BackendAuthService>(
          create: (ctx) => BackendAuthService(
            apiClient: ctx.read<BackendApiClient>(),
          ),
        ),

        // Repositories
        Provider<ProfileRepositorySupabase>(
          create: (ctx) => ProfileRepositorySupabase(
            supabaseService: ctx.read<SupabaseService>(),
          ),
        ),
        Provider<ProfileRepository>(
          create: (ctx) => ProfileRepositoryHybrid(
            backendApiClient: ctx.read<BackendApiClient>(),
            supabaseRepository: ctx.read<ProfileRepositorySupabase>(),
          ),
        ),
        Provider<AuthRepository>(
          create: (ctx) => AuthRepositoryBackend(
            authService: ctx.read<BackendAuthService>(),
            sessionStore: ctx.read<AuthSessionStore>(),
            profileRepository: ctx.read<ProfileRepository>(),
          ),
        ),
        Provider<AcademyRepository>(
          create: (ctx) => AcademyRepositorySupabase(
            supabaseService: ctx.read<SupabaseService>(),
          ),
        ),
        Provider<StudentsRepository>(
          create: (ctx) => StudentsRepositoryHybrid(
            backendApiClient: ctx.read<BackendApiClient>(),
            fallbackRepository: StudentsRepositorySupabase(
              supabaseService: ctx.read<SupabaseService>(),
            ),
          ),
        ),
        Provider<AcademySearchRepository>(
          create: (ctx) => AcademySearchRepositorySupabase(
            supabaseService: ctx.read<SupabaseService>(),
          ),
        ),
        Provider<ClassScheduleRepository>(
          create: (ctx) => ClassScheduleRepositoryHybrid(
            backendApiClient: ctx.read<BackendApiClient>(),
            fallbackRepository: ClassScheduleRepositorySupabase(),
          ),
        ),

        // Services Globais
        ChangeNotifierProvider<ProfileService>(
          create: (ctx) => ProfileService(
            profileRepository: ctx.read<ProfileRepository>(),
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
