import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:self_dojo_mobile/ui/features/academy/widgets/create_academy_screen.dart';
import 'package:self_dojo_mobile/ui/features/academy/widgets/graduation_config_screen.dart';
import 'package:self_dojo_mobile/ui/features/academy/widgets/manage_academy_screen.dart';
import 'package:self_dojo_mobile/ui/features/academy/widgets/modalities_screen.dart';
import 'package:self_dojo_mobile/ui/features/auth/view_models/auth_viewmodel.dart';
import 'package:self_dojo_mobile/ui/features/auth/widgets/login_screen.dart';
import 'package:self_dojo_mobile/ui/features/auth/widgets/register_screen.dart';
import 'package:self_dojo_mobile/ui/features/home/widgets/home_screen.dart';
import 'package:self_dojo_mobile/ui/features/profile/widgets/edit_profile_screen.dart';
import 'package:self_dojo_mobile/ui/features/splash/widgets/splash_screen.dart';

/// Rotas do aplicativo
abstract class AppRoutes {
  // Auth
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';

  // Home
  static const home = '/home';

  // Profile
  static const editProfile = '/profile/edit';

  // Academy
  static const createAcademy = '/academy/create';
  static const manageAcademy = '/academy/manage';
  static const academyModalities = '/academy/modalities';
  static const academyGraduation = '/academy/modalities/:type/graduation';
  static const academyStudents = '/academy/students';
  static const academyRequests = '/academy/requests';
  static const academyTeachers = '/academy/teachers';
  static const academyEdit = '/academy/edit';
  static const academySubscription = '/academy/subscription';
}

/// Configuração do GoRouter
class AppRouter {
  AppRouter({required AuthViewModel authViewModel})
      : _authViewModel = authViewModel;

  final AuthViewModel _authViewModel;

  late final router = GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: _authViewModel,
    redirect: _redirect,
    routes: _routes,
  );

  /// Redirecionamento baseado no estado de autenticação
  String? _redirect(BuildContext context, GoRouterState state) {
    final isInitializing = _authViewModel.isInitializing;
    final isAuthenticated = _authViewModel.isAuthenticated;
    final currentPath = state.matchedLocation;

    // Se está inicializando, permanece no splash
    if (isInitializing) {
      return currentPath == AppRoutes.splash ? null : AppRoutes.splash;
    }

    // Rotas de autenticação
    final isAuthRoute = currentPath == AppRoutes.login ||
        currentPath == AppRoutes.register ||
        currentPath == AppRoutes.splash;

    // Se autenticado e em rota de auth, vai para home
    if (isAuthenticated && isAuthRoute) {
      return AppRoutes.home;
    }

    // Se não autenticado e não está em rota de auth, vai para login
    if (!isAuthenticated && !isAuthRoute) {
      return AppRoutes.login;
    }

    // Se está no splash e não está inicializando, vai para login
    if (currentPath == AppRoutes.splash && !isInitializing) {
      return AppRoutes.login;
    }

    return null;
  }

  /// Definição das rotas
  List<RouteBase> get _routes => [
        // Auth
        GoRoute(
          path: AppRoutes.splash,
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: AppRoutes.register,
          pageBuilder: (context, state) => _slideTransition(
            state,
            const RegisterScreen(),
            slideFromRight: true,
          ),
        ),

        // Home
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const HomeScreen(),
        ),

        // Profile
        GoRoute(
          path: AppRoutes.editProfile,
          pageBuilder: (context, state) => _slideTransition(
            state,
            const EditProfileScreen(),
            slideFromBottom: true,
          ),
        ),

        // Academy
        GoRoute(
          path: AppRoutes.createAcademy,
          pageBuilder: (context, state) => _slideTransition(
            state,
            const CreateAcademyScreen(),
            slideFromRight: true,
          ),
        ),
        GoRoute(
          path: AppRoutes.manageAcademy,
          builder: (context, state) => const ManageAcademyScreen(),
        ),
        GoRoute(
          path: AppRoutes.academyModalities,
          pageBuilder: (context, state) => _slideTransition(
            state,
            const ModalitiesScreen(),
            slideFromRight: true,
          ),
        ),
        GoRoute(
          path: AppRoutes.academyGraduation,
          pageBuilder: (context, state) {
            final type = state.pathParameters['type'] ?? 'jiuJitsu';
            return _slideTransition(
              state,
              GraduationConfigScreen(modalityType: type),
              slideFromRight: true,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.academyStudents,
          builder: (context, state) => const _PlaceholderScreen(title: 'Alunos'),
        ),
        GoRoute(
          path: AppRoutes.academyRequests,
          builder: (context, state) =>
              const _PlaceholderScreen(title: 'Solicitações'),
        ),
        GoRoute(
          path: AppRoutes.academyTeachers,
          builder: (context, state) => const _PlaceholderScreen(title: 'Equipe'),
        ),
        GoRoute(
          path: AppRoutes.academyEdit,
          builder: (context, state) =>
              const _PlaceholderScreen(title: 'Editar Academia'),
        ),
        GoRoute(
          path: AppRoutes.academySubscription,
          builder: (context, state) =>
              const _PlaceholderScreen(title: 'Assinatura'),
        ),
      ];

  /// Transição com slide
  CustomTransitionPage _slideTransition(
    GoRouterState state,
    Widget child, {
    bool slideFromRight = false,
    bool slideFromBottom = false,
  }) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final begin = slideFromBottom
            ? const Offset(0, 1)
            : slideFromRight
                ? const Offset(1, 0)
                : const Offset(-1, 0);
        return SlideTransition(
          position: Tween<Offset>(
            begin: begin,
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
          ),
          child: child,
        );
      },
    );
  }
}

/// Tela placeholder para rotas não implementadas
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.construction,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Em desenvolvimento',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Esta funcionalidade será implementada em breve',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
