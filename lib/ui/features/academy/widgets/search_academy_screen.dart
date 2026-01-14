import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:self_dojo_mobile/core/theme/app_colors.dart';
import 'package:self_dojo_mobile/data/repositories/academy_search_repository.dart';
import 'package:self_dojo_mobile/domain/models/academy/academy_search_result.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/martial_art.dart';
import 'package:self_dojo_mobile/ui/features/academy/view_models/search_academy_viewmodel.dart';
import 'package:self_dojo_mobile/ui/features/auth/view_models/auth_viewmodel.dart';

/// Tela de busca de academias para alunos
class SearchAcademyScreen extends StatelessWidget {
  const SearchAcademyScreen({super.key});

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
      create: (ctx) => SearchAcademyViewModel(
        searchRepository: ctx.read<AcademySearchRepository>(),
        userId: userId,
      ),
      child: const _SearchAcademyContent(),
    );
  }
}

class _SearchAcademyContent extends StatefulWidget {
  const _SearchAcademyContent();

  @override
  State<_SearchAcademyContent> createState() => _SearchAcademyContentState();
}

class _SearchAcademyContentState extends State<_SearchAcademyContent> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Carrega academias automaticamente ao abrir a tela
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SearchAcademyViewModel>().search('');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SearchAcademyViewModel>();

    return Scaffold(
      body: Container(
        decoration: _backgroundDecoration,
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              _buildSearchBar(viewModel),
              _buildFilterChips(viewModel),
              Expanded(
                child: viewModel.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : !viewModel.hasSearched
                        ? _buildInitialState()
                        : viewModel.academies.isEmpty
                            ? _buildEmptyState(viewModel)
                            : _buildAcademyList(viewModel),
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

  Widget _buildAppBar(BuildContext context) {
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
              'Buscar Academia',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryDark,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildSearchBar(SearchAcademyViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocus,
        onSubmitted: (value) => viewModel.search(value),
        style: const TextStyle(color: AppColors.textPrimaryDark),
        decoration: InputDecoration(
          hintText: 'Nome da academia ou cidade...',
          hintStyle: TextStyle(color: AppColors.textTertiaryDark),
          prefixIcon: Icon(Icons.search, color: AppColors.textTertiaryDark),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.clear, color: AppColors.textTertiaryDark),
                  onPressed: () {
                    _searchController.clear();
                    viewModel.clearSearch();
                  },
                ),
              IconButton(
                icon: const Icon(Icons.search, color: AppColors.primary),
                onPressed: () => viewModel.search(_searchController.text),
              ),
            ],
          ),
          filled: true,
          fillColor: AppColors.surfaceDark.withValues(alpha: 0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(SearchAcademyViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: SizedBox(
        height: 36,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _buildFilterChip(
              label: 'Todas',
              isSelected: viewModel.filterModality == null,
              onTap: () => viewModel.filterByModality(null),
            ),
            ...MartialArtsConfig.all.map((art) {
              return _buildFilterChip(
                label: art.shortName,
                isSelected: viewModel.filterModality == art.type,
                color: art.primaryColor,
                onTap: () => viewModel.filterByModality(art.type),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    Color? color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (color ?? AppColors.primary).withValues(alpha: 0.2)
              : AppColors.surfaceDark.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? (color ?? AppColors.primary)
                : AppColors.surfaceVariantDark.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? (color ?? AppColors.primary)
                : AppColors.textSecondaryDark,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search,
                size: 64,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Encontre sua academia',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Busque pelo nome da academia\nou pela cidade',
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

  Widget _buildEmptyState(SearchAcademyViewModel viewModel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: AppColors.textTertiaryDark,
            ),
            const SizedBox(height: 24),
            const Text(
              'Nenhuma academia encontrada',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tente buscar com outros termos\nou filtros',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcademyList(SearchAcademyViewModel viewModel) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: viewModel.academies.length,
      itemBuilder: (context, index) {
        final academy = viewModel.academies[index];
        final status = viewModel.getRequestStatus(academy.id);
        return _AcademyCard(
          academy: academy,
          requestStatus: status,
          onRequestJoin: () => _showJoinDialog(context, academy, viewModel),
          onCancelRequest: () => _cancelRequest(context, academy, viewModel),
        );
      },
    );
  }

  void _showJoinDialog(
    BuildContext context,
    AcademySearchResult academy,
    SearchAcademyViewModel viewModel,
  ) {
    final messageController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    image: academy.logoUrl != null
                        ? DecorationImage(
                            image: NetworkImage(academy.logoUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: academy.logoUrl == null
                      ? const Icon(
                          Icons.business,
                          color: AppColors.primary,
                          size: 24,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        academy.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryDark,
                        ),
                      ),
                      if (academy.location.isNotEmpty)
                        Text(
                          academy.location,
                          style: const TextStyle(
                            color: AppColors.textSecondaryDark,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Info
            const Text(
              'Solicitar Vínculo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sua solicitação será enviada para análise. A academia irá revisar seus dados e aprovar ou rejeitar o vínculo.',
              style: TextStyle(
                color: AppColors.textSecondaryDark,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),

            // Mensagem opcional
            TextField(
              controller: messageController,
              maxLines: 3,
              style: const TextStyle(color: AppColors.textPrimaryDark),
              decoration: InputDecoration(
                labelText: 'Mensagem (opcional)',
                labelStyle: const TextStyle(color: AppColors.textSecondaryDark),
                hintText: 'Ex: Treino há 2 anos, faixa azul...',
                hintStyle: TextStyle(color: AppColors.textTertiaryDark),
                filled: true,
                fillColor: AppColors.backgroundDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Botões
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(bottomSheetContext),
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
                    onPressed: () async {
                      Navigator.pop(bottomSheetContext);
                      final result = await viewModel.sendJoinRequest.execute(
                        SendJoinRequestParams(
                          academyId: academy.id,
                          message: messageController.text.isNotEmpty
                              ? messageController.text
                              : null,
                        ),
                      );

                      if (context.mounted) {
                        result.fold(
                          onSuccess: (_) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Solicitação enviada com sucesso!'),
                                backgroundColor: AppColors.success,
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
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Enviar Solicitação'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _cancelRequest(
    BuildContext context,
    AcademySearchResult academy,
    SearchAcademyViewModel viewModel,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Cancelar Solicitação',
          style: TextStyle(color: AppColors.textPrimaryDark),
        ),
        content: Text(
          'Deseja cancelar sua solicitação para ${academy.name}?',
          style: const TextStyle(color: AppColors.textSecondaryDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Não'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final result =
                  await viewModel.cancelJoinRequest.execute(academy.id);

              if (context.mounted) {
                result.fold(
                  onSuccess: (_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Solicitação cancelada'),
                        backgroundColor: AppColors.success,
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
            ),
            child: const Text('Sim, cancelar'),
          ),
        ],
      ),
    );
  }
}

/// Card de academia
class _AcademyCard extends StatelessWidget {
  const _AcademyCard({
    required this.academy,
    required this.requestStatus,
    required this.onRequestJoin,
    required this.onCancelRequest,
  });

  final AcademySearchResult academy;
  final MemberRequestStatus requestStatus;
  final VoidCallback onRequestJoin;
  final VoidCallback onCancelRequest;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getBorderColor(),
        ),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Logo
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    image: academy.logoUrl != null
                        ? DecorationImage(
                            image: NetworkImage(academy.logoUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: academy.logoUrl == null
                      ? const Icon(
                          Icons.business,
                          color: AppColors.primary,
                          size: 28,
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        academy.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryDark,
                        ),
                      ),
                      if (academy.location.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: AppColors.textTertiaryDark,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              academy.location,
                              style: TextStyle(
                                color: AppColors.textSecondaryDark,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (academy.modalitiesText.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          academy.modalitiesText,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Descrição
          if (academy.description != null &&
              academy.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                academy.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondaryDark,
                  fontSize: 13,
                ),
              ),
            ),

          // Ação
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppColors.surfaceVariantDark.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: _buildActionButton(),
          ),
        ],
      ),
    );
  }

  Color _getBorderColor() {
    switch (requestStatus) {
      case MemberRequestStatus.pending:
        return AppColors.warning.withValues(alpha: 0.3);
      case MemberRequestStatus.approved:
        return AppColors.success.withValues(alpha: 0.3);
      default:
        return AppColors.surfaceVariantDark.withValues(alpha: 0.3);
    }
  }

  Widget _buildActionButton() {
    switch (requestStatus) {
      case MemberRequestStatus.pending:
        return Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.hourglass_empty,
                      size: 18,
                      color: AppColors.warning,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Aguardando aprovação',
                      style: TextStyle(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: onCancelRequest,
              icon: const Icon(Icons.close, color: AppColors.error),
              tooltip: 'Cancelar solicitação',
            ),
          ],
        );

      case MemberRequestStatus.approved:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle,
                size: 18,
                color: AppColors.success,
              ),
              SizedBox(width: 8),
              Text(
                'Você é membro',
                style: TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );

      default:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onRequestJoin,
            icon: const Icon(Icons.person_add, size: 18),
            label: const Text('Solicitar Vínculo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        );
    }
  }
}

