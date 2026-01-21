import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:self_dojo_mobile/core/navigation/app_navigation.dart';
import 'package:self_dojo_mobile/core/theme/app_colors.dart';
import 'package:self_dojo_mobile/data/repositories/academy_repository.dart';
import 'package:self_dojo_mobile/data/services/profile_service.dart';
import 'package:self_dojo_mobile/domain/models/user_profile.dart';
import 'package:self_dojo_mobile/ui/features/auth/view_models/auth_viewmodel.dart';

/// Splash Screen
/// Exibida enquanto o app inicializa
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _hasCheckedOwner = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();
    
    // Inicializa o ProfileService e verifica redirecionamento do owner
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAndCheckOwner();
    });
  }
  
  Future<void> _initializeAndCheckOwner() async {
    if (_hasCheckedOwner || !mounted) return;
    
    final authViewModel = context.read<AuthViewModel>();
    final profileService = context.read<ProfileService>();
    final user = authViewModel.user;

    // Se não estiver autenticado, não faz nada (o router vai redirecionar)
    if (!authViewModel.isAuthenticated || user.id.isEmpty) {
      return;
    }

    // Inicializa o ProfileService
    await profileService.init(
      user.id,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoUrl,
    );

    if (!mounted) return;

    // Aguarda o ProfileService terminar de carregar (polling até não estar mais loading)
    int attempts = 0;
    while (profileService.isLoading && mounted && attempts < 100) {
      await Future.delayed(const Duration(milliseconds: 50));
      attempts++;
    }

    if (!mounted) return;

    // Verifica se o perfil foi carregado corretamente
    UserProfile profile = profileService.profile;
    
    // Se o perfil ainda não foi carregado, aguarda mais um pouco
    if (profile.id.isEmpty || profile.id != user.id) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      profile = profileService.profile;
    }
    
    _hasCheckedOwner = true;
    
    if (profile.isOwner) {
      final ownerId = user.id;
      final academyRepository = context.read<AcademyRepository>();
      final result = await academyRepository.getOwnerAcademies(ownerId);
      
      if (!mounted) return;
      
      result.fold(
        onSuccess: (academies) {
          if (!mounted) return;
          if (academies.isEmpty) {
            AppNavigation.goToCreateAcademy(context);
          } else if (academies.length == 1) {
            AppNavigation.goToManageAcademy(
              context,
              academyId: academies.first.id,
            );
          } else {
            AppNavigation.goToSelectAcademy(context);
          }
        },
        onFailure: (_) {
          // Em caso de erro, redireciona para home
          if (mounted) {
            AppNavigation.goToHome(context);
          }
        },
      );
    } else {
      // Se não for owner, redireciona para home
      if (mounted) {
        AppNavigation.goToHome(context);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.backgroundDark,
              Color(0xFF1a1a3e),
              AppColors.backgroundDark,
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: child,
                  ),
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Container
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'SD',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // App Name
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        AppColors.primaryGradient.createShader(bounds),
                    child: const Text(
                      'Self Dojo',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Seu dojo de autodesenvolvimento',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondaryDark.withValues(alpha: 0.8),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 64),
                  // Loading indicator
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

