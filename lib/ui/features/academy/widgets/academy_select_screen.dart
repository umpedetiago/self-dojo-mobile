import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:self_dojo_mobile/core/theme/app_colors.dart';
import 'package:self_dojo_mobile/data/repositories/academy_repository.dart';
import 'package:self_dojo_mobile/domain/models/academy/academy.dart';
import 'package:self_dojo_mobile/ui/features/auth/view_models/auth_viewmodel.dart';

/// Tela de seleção de academia para owners.
/// - Se houver 1 academia, entra direto nela.
/// - Se houver mais de 1, lista para o usuário escolher.
class AcademySelectScreen extends StatefulWidget {
  const AcademySelectScreen({super.key});

  @override
  State<AcademySelectScreen> createState() => _AcademySelectScreenState();
}

class _AcademySelectScreenState extends State<AcademySelectScreen> {
  bool _isLoading = true;
  String? _error;
  List<Academy> _academies = const [];
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final authViewModel = context.read<AuthViewModel>();
    final academyRepository = context.read<AcademyRepository>();
    final ownerId = authViewModel.user.id;

    if (ownerId.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = 'Usuário não autenticado';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await academyRepository.getOwnerAcademies(ownerId);
    result.fold(
      onSuccess: (academies) {
        _academies = academies;
        _isLoading = false;
        _error = null;
        if (mounted) setState(() {});

        if (_navigated) return;

        // 0 academias -> vai para criar (mantém fluxo atual do app)
        if (academies.isEmpty) {
          _navigated = true;
          context.go('/academy/create');
          return;
        }

        // 1 academia -> entra direto
        if (academies.length == 1) {
          _navigated = true;
          context.go('/academy/manage/${academies.first.id}');
        }
      },
      onFailure: (failure) {
        setState(() {
          _isLoading = false;
          _error = failure.message;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar Academia'),
        backgroundColor: AppColors.surfaceDark,
      ),
      body: Container(
        decoration: _backgroundDecoration,
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline,
                                color: AppColors.error, size: 40),
                            const SizedBox(height: 12),
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _load,
                              child: const Text('Tentar novamente'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _academies.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final academy = _academies[index];
                        return _AcademyCard(
                          academy: academy,
                          onTap: () => context.go(
                            '/academy/manage/${academy.id}',
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }

  BoxDecoration get _backgroundDecoration => const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1a1a3e),
            AppColors.backgroundDark,
          ],
        ),
      );
}

class _AcademyCard extends StatelessWidget {
  const _AcademyCard({
    required this.academy,
    required this.onTap,
  });

  final Academy academy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceDark.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                child: const Icon(Icons.business, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      academy.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if ((academy.city ?? '').isNotEmpty) academy.city!,
                        if ((academy.state ?? '').isNotEmpty) academy.state!,
                      ].join(' - '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white60),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }
}

