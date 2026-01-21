import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:self_dojo_mobile/core/theme/app_colors.dart';
import 'package:self_dojo_mobile/data/repositories/academy_repository.dart';
import 'package:self_dojo_mobile/data/repositories/profile_repository.dart';
import 'package:self_dojo_mobile/domain/models/academy/academy_modality.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/martial_art.dart';
import 'package:self_dojo_mobile/ui/features/auth/view_models/auth_viewmodel.dart';
import 'package:self_dojo_mobile/ui/features/academy/view_models/academy_viewmodel.dart';
import 'package:self_dojo_mobile/data/services/supabase_service.dart';

/// Tela de gerenciamento de modalidades
class ModalitiesScreen extends StatelessWidget {
  const ModalitiesScreen({super.key});

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
        profileRepository: ctx.read<ProfileRepository>(),
        userId: userId,
      ),
      child: const _ModalitiesContent(),
    );
  }
}

/// Bottom sheet para gerenciar professores de uma modalidade
class _ManageTeachersSheet extends StatefulWidget {
  const _ManageTeachersSheet({
    required this.modality,
    required this.academyId,
    required this.academyViewModel,
    required this.onUpdated,
  });

  final AcademyModality modality;
  final String academyId;
  final AcademyViewModel academyViewModel;
  final void Function(List<String> teacherIds) onUpdated;

  @override
  State<_ManageTeachersSheet> createState() => _ManageTeachersSheetState();
}

class _ManageTeachersSheetState extends State<_ManageTeachersSheet> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  List<Map<String, dynamic>> _members = [];
  Set<String> _selectedUserIds = {};
  String? _ownerUserId; // id do usuário no banco (não o firebase_uid)
  bool _includeOwner = false;
  String? _masterUserId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final supabase = context.read<SupabaseService>();
      final auth = context.read<AuthViewModel>();

      // Owner (buscar user_id pelo firebase_uid)
      final ownerUser =
          await supabase.getUserByFirebaseUid(auth.user.id);
      _ownerUserId = ownerUser?['id'] as String?;

      // Membros da academia
      final members =
          await supabase.getAcademyMembers(widget.academyId, status: 'approved');

      // Professores atuais da modalidade
      final teachers =
          await supabase.getModalityTeachers(widget.modality.id);

      final currentTeacherIds = teachers
          .where(
            (t) => t['user_id'] is String,
          )
          .map<String>((t) => t['user_id'] as String)
          .toSet();

      // Mestre atual (se existir) – vindo da própria modalidade
      final masterId = widget.modality.masterId;

      final includeOwner =
          _ownerUserId != null && currentTeacherIds.contains(_ownerUserId);

      setState(() {
        _members = members;
        _selectedUserIds = currentTeacherIds;
        _includeOwner = includeOwner;
        _masterUserId = masterId;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar professores: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final supabase = context.read<SupabaseService>();
      final academyViewModel = widget.academyViewModel;

      final teacherIds = {
        ..._selectedUserIds,
        if (_includeOwner && _ownerUserId != null) _ownerUserId!,
      }.toList();

      await supabase.setModalityTeachers(widget.modality.id, teacherIds);

      // Atualiza mestre da modalidade (opcional)
      await academyViewModel.setModalityMaster(
        widget.modality.martialArt.type,
        _masterUserId,
      );

      widget.onUpdated(teacherIds);

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Professores e mestre atualizados com sucesso'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar professores: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final martialArt = widget.modality.martialArt;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: martialArt.primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    martialArt.icon,
                    color: martialArt.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Professores - ${martialArt.shortName}',
                    style: const TextStyle(
                      color: AppColors.textPrimaryDark,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Selecione os membros que são professores nesta modalidade.',
              style: TextStyle(
                color: AppColors.textSecondaryDark,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child:
                      CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 13,
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _members.length,
                  separatorBuilder: (_, __) => const Divider(
                    color: Color(0x22FFFFFF),
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final member = _members[index];
                    final user = member['users'] as Map<String, dynamic>?;
                    final userId = member['user_id'] as String?;
                    if (userId == null) return const SizedBox.shrink();

                    final name =
                        user?['display_name'] as String? ?? 'Sem nome';
                    final email = user?['email'] as String? ?? '';
                    final isSelected = _selectedUserIds.contains(userId);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CheckboxListTile(
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedUserIds.add(userId);
                              } else {
                                _selectedUserIds.remove(userId);
                                if (_masterUserId == userId) {
                                  _masterUserId = null;
                                }
                              }
                            });
                          },
                          activeColor: AppColors.primary,
                          title: Text(
                            name,
                            style: const TextStyle(
                              color: AppColors.textPrimaryDark,
                            ),
                          ),
                          subtitle: email.isNotEmpty
                              ? Text(
                                  email,
                                  style: const TextStyle(
                                    color: AppColors.textSecondaryDark,
                                    fontSize: 12,
                                  ),
                                )
                              : null,
                        ),
                        if (_selectedUserIds.contains(userId))
                          RadioListTile<String>(
                            value: userId,
                            groupValue: _masterUserId,
                            onChanged: (value) {
                              setState(() {
                                _masterUserId = value;
                              });
                            },
                            activeColor: AppColors.secondary,
                            title: const Text(
                              'Definir como Mestre da modalidade',
                              style: TextStyle(
                                color: AppColors.textSecondaryDark,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            if (_ownerUserId != null)
              CheckboxListTile(
                value: _includeOwner,
                onChanged: (value) {
                  setState(() {
                    _includeOwner = value ?? false;
                  });
                },
                activeColor: AppColors.primary,
                title: const Text(
                  'Incluir-me como professor nesta modalidade',
                  style: TextStyle(color: AppColors.textPrimaryDark),
                ),
                subtitle: const Text(
                  'Você (owner) aparecerá como professor mesmo sem estar na lista de membros.',
                  style: TextStyle(
                    color: AppColors.textSecondaryDark,
                    fontSize: 12,
                  ),
                ),
              ),
            if (_members.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8, bottom: 4),
                child: Text(
                  'Nenhum membro aprovado na academia.',
                  style: TextStyle(
                    color: AppColors.textSecondaryDark,
                    fontSize: 14,
                  ),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving || _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check),
                label: Text(
                  _isSaving ? 'Salvando...' : 'Salvar',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _ModalitiesContent extends StatelessWidget {
  const _ModalitiesContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AcademyViewModel>();

    if (viewModel.isLoading) {
      return Scaffold(
        body: Container(
          decoration: _backgroundDecoration,
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      );
    }

    final academy = viewModel.academy;
    final modalities = academy.modalities;

    return Scaffold(
      body: Container(
        decoration: _backgroundDecoration,
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context, viewModel),
              Expanded(
                child: modalities.isEmpty
                    ? _buildEmptyState(context, viewModel)
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: modalities.length,
                        itemBuilder: (context, index) {
                          return _buildModalityCard(
                            context,
                            modalities[index],
                            viewModel,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: viewModel.canAddModality
          ? FloatingActionButton.extended(
              onPressed: () => _showAddModalityDialog(context, viewModel),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Adicionar',
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }

  Widget _buildEmptyState(BuildContext context, AcademyViewModel viewModel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_martial_arts,
              size: 80,
              color: AppColors.textTertiaryDark,
            ),
            const SizedBox(height: 24),
            const Text(
              'Nenhuma modalidade',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Adicione as artes marciais\nque sua academia oferece',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondaryDark,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showAddModalityDialog(context, viewModel),
              icon: const Icon(Icons.add),
              label: const Text('Adicionar Modalidade'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
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

  Widget _buildAppBar(BuildContext context, AcademyViewModel viewModel) {
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
              'Modalidades',
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

  Widget _buildModalityCard(
    BuildContext context,
    AcademyModality modality,
    AcademyViewModel viewModel,
  ) {
    final martialArt = modality.martialArt;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: martialArt.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: martialArt.primaryColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child:               Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: martialArt.primaryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      martialArt.icon,
                      color: martialArt.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          martialArt.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimaryDark,
                          ),
                        ),
                        Text(
                          modality.graduationConfig.useDefaultConfig
                              ? 'Graduação padrão'
                              : 'Graduação personalizada',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!modality.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Inativa',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: AppColors.textSecondaryDark,
                    ),
                    color: AppColors.surfaceDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (value) {
                      if (value == 'remove') {
                        _showRemoveModalityDialog(
                          context,
                          modality,
                          viewModel,
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'remove',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              color: AppColors.error,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Remover modalidade',
                              style: TextStyle(color: AppColors.error),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Mestre
                _buildInfoRow(
                  Icons.person,
                  'Mestre',
                  modality.masterName?.isNotEmpty == true
                      ? modality.masterName!
                      : modality.masterId != null
                          ? 'Definido'
                          : 'Não definido',
                ),
                const SizedBox(height: 8),
                // Professores
                _buildInfoRow(
                  Icons.school,
                  'Professores',
                  '${modality.teacherIds.length}',
                ),
                const SizedBox(height: 8),
                // Faixas
                _buildInfoRow(
                  Icons.military_tech,
                  'Faixas',
                  '${martialArt.belts.length}',
                ),
              ],
            ),
          ),

          // Actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    onPressed: () {
                      context.push(
                        '/academy/modalities/${modality.type.name}/graduation',
                      );
                    },
                    icon: const Icon(Icons.tune, size: 18),
                    label: const Text('Graduações'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimaryDark,
                      side: BorderSide(
                        color: AppColors.surfaceVariantDark.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showManageTeachersDialog(context, modality, viewModel);
                    },
                    icon: const Icon(Icons.school, size: 18),
                    label: const Text('Professores'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimaryDark,
                      side: BorderSide(
                        color: AppColors.surfaceVariantDark.withValues(alpha: 0.5),
                      ),
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

  void _showManageTeachersDialog(
    BuildContext context,
    AcademyModality modality,
    AcademyViewModel viewModel,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ManageTeachersSheet(
        modality: modality,
        academyId: viewModel.academy.id,
        academyViewModel: viewModel,
        onUpdated: (teacherIds) {
          final updated = modality.copyWith(teacherIds: teacherIds);
          viewModel.updateLocalModality(updated);
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textTertiaryDark),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: const TextStyle(
            color: AppColors.textSecondaryDark,
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimaryDark,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _showAddModalityDialog(
      BuildContext context, AcademyViewModel viewModel) {
    final existingTypes = viewModel.academy.modalityTypes;
    final availableArts = MartialArtsConfig.all
        .where((art) => !existingTypes.contains(art.type))
        .toList();

    if (availableArts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todas as modalidades já foram adicionadas'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Adicionar Modalidade',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryDark,
              ),
            ),
            const SizedBox(height: 16),
            ...availableArts.map((art) => ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: art.primaryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(art.icon, color: art.primaryColor),
                  ),
                  title: Text(
                    art.name,
                    style: const TextStyle(color: AppColors.textPrimaryDark),
                  ),
                  subtitle: Text(
                    '${art.belts.length} faixas',
                    style: const TextStyle(color: AppColors.textSecondaryDark),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    final result =
                        await viewModel.addModality.execute(art.type);
                    if (context.mounted) {
                      result.fold(
                        onSuccess: (_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('${art.name} adicionada com sucesso!'),
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
                )),
          ],
        ),
      ),
    );
  }

  // OBS: seleção de mestre será implementada futuramente com base nos professores cadastrados

  void _showRemoveModalityDialog(
    BuildContext context,
    AcademyModality modality,
    AcademyViewModel viewModel,
  ) {
    final martialArt = modality.martialArt;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: AppColors.warning,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Remover Modalidade',
                style: TextStyle(
                  color: AppColors.textPrimaryDark,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tem certeza que deseja remover ${martialArt.name}?',
              style: const TextStyle(
                color: AppColors.textPrimaryDark,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.error,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta ação não pode ser desfeita. As graduações dos alunos nesta modalidade serão mantidas.',
                      style: TextStyle(
                        color: AppColors.textSecondaryDark,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textSecondaryDark),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final result =
                  await viewModel.removeModality.execute(modality.type);
              if (context.mounted) {
                result.fold(
                  onSuccess: (_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${martialArt.name} removida com sucesso'),
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
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }
}

