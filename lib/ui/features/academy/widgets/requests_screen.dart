import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:self_dojo_mobile/core/theme/app_colors.dart';
import 'package:self_dojo_mobile/data/repositories/academy_repository.dart';
import 'package:self_dojo_mobile/data/repositories/academy_search_repository.dart';
import 'package:self_dojo_mobile/data/repositories/students_repository.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/martial_art.dart';
import 'package:self_dojo_mobile/ui/features/academy/view_models/academy_viewmodel.dart';
import 'package:self_dojo_mobile/ui/features/academy/view_models/requests_viewmodel.dart';
import 'package:self_dojo_mobile/ui/features/auth/view_models/auth_viewmodel.dart';

/// Tela de gerenciamento de solicitações de vínculo
class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final userId = authViewModel.user.id;

    if (userId.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return ChangeNotifierProvider(
      create: (ctx) => AcademyViewModel(
        academyRepository: ctx.read<AcademyRepository>(),
        profileRepository: ctx.read(),
        userId: userId,
      ),
      child: const _RequestsScreenLoader(),
    );
  }
}

class _RequestsScreenLoader extends StatelessWidget {
  const _RequestsScreenLoader();

  @override
  Widget build(BuildContext context) {
    final academyViewModel = context.watch<AcademyViewModel>();

    if (academyViewModel.isLoading) {
      return Scaffold(
        body: Container(
          decoration: _backgroundDecoration,
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      );
    }

    if (!academyViewModel.hasAcademy) {
      return Scaffold(
        body: Container(
          decoration: _backgroundDecoration,
          child: const Center(
            child: Text(
              'Academia não encontrada',
              style: TextStyle(color: AppColors.textPrimaryDark),
            ),
          ),
        ),
      );
    }

    return ChangeNotifierProvider(
      create: (ctx) => RequestsViewModel(
        searchRepository: ctx.read<AcademySearchRepository>(),
        academyId: academyViewModel.academy.id,
      ),
      child: _RequestsContent(
        academyModalities: academyViewModel.academy.modalityTypes,
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

class _RequestsContent extends StatelessWidget {
  const _RequestsContent({required this.academyModalities});

  final List<MartialArtType> academyModalities;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<RequestsViewModel>();

    return Scaffold(
      body: Container(
        decoration: _backgroundDecoration,
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context, viewModel),
              Expanded(
                child: viewModel.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : viewModel.requests.isEmpty
                        ? _buildEmptyState()
                        : _buildRequestsList(context, viewModel),
              ),
            ],
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

  Widget _buildAppBar(BuildContext context, RequestsViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: AppColors.textPrimaryDark,
            ),
          ),
          const Expanded(
            child: Text(
              'Solicitações',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryDark,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Badge com contagem
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: viewModel.requestCount > 0
                  ? AppColors.warning.withValues(alpha: 0.2)
                  : AppColors.surfaceVariantDark.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${viewModel.requestCount}',
              style: TextStyle(
                color: viewModel.requestCount > 0
                    ? AppColors.warning
                    : AppColors.textSecondaryDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 64,
                color: AppColors.success.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Nenhuma solicitação',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Todas as solicitações foram\nprocessadas',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsList(BuildContext context, RequestsViewModel viewModel) {
    return RefreshIndicator(
      onRefresh: viewModel.refresh,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: viewModel.requests.length,
        itemBuilder: (context, index) {
          final request = viewModel.requests[index];
          return _RequestCard(
            request: request,
            academyModalities: academyModalities,
            onApprove: () => _approveRequest(context, request, viewModel),
            onReject: () => _rejectRequest(context, request, viewModel),
          );
        },
      ),
    );
  }

  void _approveRequest(
    BuildContext context,
    JoinRequest request,
    RequestsViewModel viewModel,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) => _ApproveRequestSheet(
        request: request,
        viewModel: viewModel,
        academyModalities: academyModalities,
      ),
    );
  }

  void _rejectRequest(
    BuildContext context,
    JoinRequest request,
    RequestsViewModel viewModel,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.cancel, color: AppColors.error),
            SizedBox(width: 12),
            Text(
              'Rejeitar Solicitação',
              style: TextStyle(color: AppColors.textPrimaryDark),
            ),
          ],
        ),
        content: Text(
          'Tem certeza que deseja rejeitar a solicitação de ${request.name}?',
          style: const TextStyle(color: AppColors.textSecondaryDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final result =
                  await viewModel.rejectRequest.execute(request.memberId);

              if (context.mounted) {
                result.fold(
                  onSuccess: (_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Solicitação de ${request.name} rejeitada'),
                        backgroundColor: AppColors.warning,
                      ),
                    );
                  },
                  onFailure: (failure) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(failure.message),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  },
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Rejeitar'),
          ),
        ],
      ),
    );
  }
}

/// Card de solicitação
class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.academyModalities,
    required this.onApprove,
    required this.onReject,
  });

  final JoinRequest request;
  final List<MartialArtType> academyModalities;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    image: request.photoUrl != null
                        ? DecorationImage(
                            image: NetworkImage(request.photoUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: request.photoUrl == null
                      ? Center(
                          child: Text(
                            request.name.isNotEmpty
                                ? request.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        request.email,
                        style: TextStyle(
                          color: AppColors.textSecondaryDark,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: AppColors.textTertiaryDark,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(request.requestedAt),
                            style: TextStyle(
                              color: AppColors.textTertiaryDark,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Badge novo
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'NOVO',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Mensagem (se houver)
          if (request.message != null && request.message!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundDark.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mensagem:',
                      style: TextStyle(
                        color: AppColors.textTertiaryDark,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      request.message!,
                      style: const TextStyle(
                        color: AppColors.textSecondaryDark,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Modalidades solicitadas (se houver)
          if (request.requestedModalities.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Icon(
                    Icons.sports_martial_arts,
                    size: 16,
                    color: AppColors.textTertiaryDark,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Modalidades: ',
                    style: TextStyle(
                      color: AppColors.textTertiaryDark,
                      fontSize: 12,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      request.requestedModalities
                          .map((t) => MartialArtsConfig.getByType(t).shortName)
                          .join(', '),
                      style: const TextStyle(
                        color: AppColors.textSecondaryDark,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Ações
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppColors.surfaceVariantDark.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Rejeitar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(
                        color: AppColors.error.withValues(alpha: 0.5),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Aprovar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return 'Agora';
    } else if (diff.inMinutes < 60) {
      return 'Há ${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      return 'Há ${diff.inHours}h';
    } else if (diff.inDays < 7) {
      return 'Há ${diff.inDays} dia${diff.inDays > 1 ? 's' : ''}';
    } else {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
    }
  }
}

/// Bottom sheet para aprovar solicitação com seleção de modalidades
class _ApproveRequestSheet extends StatefulWidget {
  const _ApproveRequestSheet({
    required this.request,
    required this.viewModel,
    required this.academyModalities,
  });

  final JoinRequest request;
  final RequestsViewModel viewModel;
  final List<MartialArtType> academyModalities;

  @override
  State<_ApproveRequestSheet> createState() => _ApproveRequestSheetState();
}

class _ApproveRequestSheetState extends State<_ApproveRequestSheet> {
  final Map<MartialArtType, bool> _selectedModalities = {};
  final Map<MartialArtType, String> _selectedBelts = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Inicializa todas modalidades como não selecionadas
    for (final type in widget.academyModalities) {
      _selectedModalities[type] = false;
      // Pega a primeira faixa (iniciante) como padrão
      final art = MartialArtsConfig.getByType(type);
      _selectedBelts[type] = art.belts.first.id;
    }
  }

  bool get _hasSelection => _selectedModalities.values.any((v) => v);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.success, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Aprovar Solicitação',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                    Text(
                      widget.request.name,
                      style: const TextStyle(
                        color: AppColors.textSecondaryDark,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: AppColors.textSecondaryDark),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Instruções
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Selecione as modalidades e a graduação inicial do aluno',
                    style: TextStyle(
                      color: AppColors.textSecondaryDark,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Lista de modalidades
          const Text(
            'Modalidades',
            style: TextStyle(
              color: AppColors.textPrimaryDark,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),

          // Modalidades da academia
          ...widget.academyModalities.map((type) => _buildModalityItem(type)),

          const SizedBox(height: 24),

          // Botões de ação
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondaryDark,
                    side: BorderSide(
                      color: AppColors.surfaceVariantDark.withValues(alpha: 0.5),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _approveAndEnroll,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Aprovar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModalityItem(MartialArtType type) {
    final art = MartialArtsConfig.getByType(type);
    final isSelected = _selectedModalities[type] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? art.primaryColor.withValues(alpha: 0.1)
            : AppColors.surfaceVariantDark.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? art.primaryColor.withValues(alpha: 0.5)
              : AppColors.surfaceVariantDark.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // Checkbox e nome da modalidade
          CheckboxListTile(
            value: isSelected,
            onChanged: (value) {
              setState(() {
                _selectedModalities[type] = value ?? false;
              });
            },
            title: Row(
              children: [
                Icon(art.icon, color: art.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  art.name,
                  style: const TextStyle(
                    color: AppColors.textPrimaryDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            activeColor: art.primaryColor,
            checkColor: Colors.white,
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          ),

          // Seletor de faixa (aparece quando selecionado)
          if (isSelected)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Graduação inicial',
                    style: TextStyle(
                      color: AppColors.textSecondaryDark,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: art.belts.length,
                      itemBuilder: (context, index) {
                        final belt = art.belts[index];
                        final isSelectedBelt = _selectedBelts[type] == belt.id;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedBelts[type] = belt.id;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelectedBelt
                                  ? belt.color.withValues(alpha: 0.2)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelectedBelt
                                    ? belt.color
                                    : AppColors.surfaceVariantDark
                                        .withValues(alpha: 0.5),
                                width: isSelectedBelt ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 16,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: belt.color,
                                    borderRadius: BorderRadius.circular(2),
                                    border: belt.color == Colors.white
                                        ? Border.all(color: Colors.grey.shade400)
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  belt.name,
                                  style: TextStyle(
                                    color: isSelectedBelt
                                        ? belt.color.computeLuminance() > 0.5
                                            ? Colors.black87
                                            : AppColors.textPrimaryDark
                                        : AppColors.textSecondaryDark,
                                    fontSize: 12,
                                    fontWeight: isSelectedBelt
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _approveAndEnroll() async {
    setState(() => _isLoading = true);

    try {
      // Primeiro aprova a solicitação
      final approveResult = await widget.viewModel.approveRequest
          .execute(widget.request.memberId);

      if (!approveResult.isSuccess) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(approveResult.fold(
                onSuccess: (_) => '',
                onFailure: (f) => f.message,
              )),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      // Matricula nas modalidades selecionadas
      final studentsRepo = context.read<StudentsRepository>();
      final academyViewModel = context.read<AcademyViewModel>();

      for (final entry in _selectedModalities.entries) {
        if (entry.value) {
          final type = entry.key;
          final beltId = _selectedBelts[type]!;

          // Busca o academy_modality_id
          final academyModality = academyViewModel.academy.modalities
              .where((m) => m.type == type)
              .firstOrNull;

          if (academyModality != null) {
            await studentsRepo.enrollInModality(
              memberId: widget.request.memberId,
              academyModalityId: academyModality.id,
              martialArtType: type.name,
              initialBeltId: beltId,
            );
          }
        }
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${widget.request.name} aprovado${_hasSelection ? ' e matriculado' : ''}!',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

