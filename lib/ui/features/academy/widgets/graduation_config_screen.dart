import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:self_dojo_mobile/core/theme/app_colors.dart';
import 'package:self_dojo_mobile/data/repositories/academy_repository.dart';
import 'package:self_dojo_mobile/data/repositories/profile_repository.dart';
import 'package:self_dojo_mobile/domain/models/academy/academy_modality.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/belt.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/martial_art.dart';
import 'package:self_dojo_mobile/ui/features/academy/view_models/academy_viewmodel.dart';
import 'package:self_dojo_mobile/ui/features/auth/view_models/auth_viewmodel.dart';

/// Tela de configuração de graduações de uma modalidade
class GraduationConfigScreen extends StatelessWidget {
  const GraduationConfigScreen({
    super.key,
    required this.modalityType,
  });

  final String modalityType;

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
      child: _GraduationConfigContent(modalityType: modalityType),
    );
  }
}

class _GraduationConfigContent extends StatefulWidget {
  const _GraduationConfigContent({required this.modalityType});

  final String modalityType;

  @override
  State<_GraduationConfigContent> createState() =>
      _GraduationConfigContentState();
}

class _GraduationConfigContentState extends State<_GraduationConfigContent> {
  late MartialArtType _type;
  late MartialArt _martialArt;
  bool _useDefault = true;
  final Map<String, BeltConfigData> _beltConfigs = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _type = MartialArtType.values.firstWhere(
      (t) => t.name == widget.modalityType,
      orElse: () => MartialArtType.jiuJitsu,
    );
    _martialArt = MartialArtsConfig.getByType(_type);
  }

  void _initializeConfigs(AcademyModality modality) {
    if (_beltConfigs.isNotEmpty) return;

    _useDefault = modality.graduationConfig.useDefaultConfig;

    for (final belt in _martialArt.belts) {
      final existingConfig = modality.graduationConfig.getBeltConfig(belt.id);

      _beltConfigs[belt.id] = BeltConfigData(
        minClasses: existingConfig?.minClasses ?? belt.minClassesForPromotion,
        minMonths: existingConfig?.minMonths ?? belt.minMonthsAtBelt,
        minClassesPerDegree: existingConfig?.minClassesPerDegree,
        requiresExam: existingConfig?.requiresExam ?? false,
      );
    }
  }

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

    final modality = viewModel.academy.getModality(_type);
    if (modality == null) {
      return Scaffold(
        body: Container(
          decoration: _backgroundDecoration,
          child: const Center(
            child: Text(
              'Modalidade não encontrada',
              style: TextStyle(color: AppColors.textPrimaryDark),
            ),
          ),
        ),
      );
    }

    _initializeConfigs(modality);

    return Scaffold(
      body: Container(
        decoration: _backgroundDecoration,
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildUseDefaultSwitch(),
                    const SizedBox(height: 20),
                    if (!_useDefault) ...[
                      const Text(
                        'Configurações por Faixa',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._martialArt.belts.skip(1).map((belt) {
                        return _buildBeltConfigCard(belt);
                      }),
                    ],
                    const SizedBox(height: 20),
                    _buildSaveButton(viewModel),
                  ],
                ),
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
          Expanded(
            child: Text(
              'Graduações - ${_martialArt.shortName}',
              style: const TextStyle(
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _martialArt.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _martialArt.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _martialArt.icon,
            color: _martialArt.primaryColor,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _martialArt.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
                Text(
                  '${_martialArt.belts.length} faixas',
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
    );
  }

  Widget _buildUseDefaultSwitch() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Usar configuração padrão',
                  style: TextStyle(
                    color: AppColors.textPrimaryDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _useDefault
                      ? 'Usando as regras padrão do sistema'
                      : 'Personalize as regras de graduação',
                  style: const TextStyle(
                    color: AppColors.textSecondaryDark,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _useDefault,
            onChanged: (value) {
              setState(() => _useDefault = value);
            },
            activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                    thumbColor: WidgetStatePropertyAll(AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildBeltConfigCard(Belt belt) {
    final config = _beltConfigs[belt.id]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: belt.color.withValues(alpha: 0.3),
        ),
      ),
      child: ExpansionTile(
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: belt.color,
            borderRadius: BorderRadius.circular(6),
            border: belt.color == Colors.white
                ? Border.all(color: Colors.grey.shade400)
                : null,
          ),
        ),
        title: Text(
          belt.name,
          style: const TextStyle(
            color: AppColors.textPrimaryDark,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          '${config.minClasses} aulas • ${config.minMonths ?? '-'} meses',
          style: const TextStyle(
            color: AppColors.textSecondaryDark,
            fontSize: 13,
          ),
        ),
        iconColor: AppColors.textSecondaryDark,
        collapsedIconColor: AppColors.textSecondaryDark,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildNumberField(
                  label: 'Aulas mínimas',
                  value: config.minClasses,
                  onChanged: (value) {
                    setState(() {
                      _beltConfigs[belt.id] = config.copyWith(minClasses: value);
                    });
                  },
                ),
                const SizedBox(height: 12),
                _buildNumberField(
                  label: 'Meses mínimos',
                  value: config.minMonths ?? 0,
                  onChanged: (value) {
                    setState(() {
                      _beltConfigs[belt.id] =
                          config.copyWith(minMonths: value > 0 ? value : null);
                    });
                  },
                ),
                if (belt.hasDegrees) ...[
                  const SizedBox(height: 12),
                  _buildNumberField(
                    label: 'Aulas por grau',
                    value: config.minClassesPerDegree ?? 30,
                    onChanged: (value) {
                      setState(() {
                        _beltConfigs[belt.id] =
                            config.copyWith(minClassesPerDegree: value);
                      });
                    },
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Exige exame',
                        style: TextStyle(
                          color: AppColors.textSecondaryDark,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Switch(
                      value: config.requiresExam,
                      onChanged: (value) {
                        setState(() {
                          _beltConfigs[belt.id] =
                              config.copyWith(requiresExam: value);
                        });
                      },
                      activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                    thumbColor: WidgetStatePropertyAll(AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondaryDark,
              fontSize: 14,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceVariantDark.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: value > 0
                    ? () => onChanged(value - 10)
                    : null,
                icon: const Icon(Icons.remove, size: 18),
                color: AppColors.textSecondaryDark,
              ),
              SizedBox(
                width: 60,
                child: TextField(
                  controller: TextEditingController(text: value.toString()),
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    color: AppColors.textPrimaryDark,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (text) {
                    final parsed = int.tryParse(text);
                    if (parsed != null) {
                      onChanged(parsed);
                    }
                  },
                ),
              ),
              IconButton(
                onPressed: () => onChanged(value + 10),
                icon: const Icon(Icons.add, size: 18),
                color: AppColors.textSecondaryDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(AcademyViewModel viewModel) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isSaving ? null : () => _saveConfig(viewModel),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Salvar Configurações',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Future<void> _saveConfig(AcademyViewModel viewModel) async {
    setState(() => _isSaving = true);

    final beltConfigs = _beltConfigs.entries.map((entry) {
      return BeltConfig(
        beltId: entry.key,
        minClasses: entry.value.minClasses,
        minMonths: entry.value.minMonths,
        minClassesPerDegree: entry.value.minClassesPerDegree,
        requiresExam: entry.value.requiresExam,
      );
    }).toList();

    final config = GraduationConfig(
      martialArtType: _type,
      belts: beltConfigs,
      useDefaultConfig: _useDefault,
    );

    final result = await viewModel.updateGraduationConfig(_type, config);

    if (!mounted) return;

    setState(() => _isSaving = false);

    result.fold(
      onSuccess: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configurações salvas com sucesso!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
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
}

/// Dados temporários de configuração de faixa
class BeltConfigData {
  BeltConfigData({
    required this.minClasses,
    this.minMonths,
    this.minClassesPerDegree,
    this.requiresExam = false,
  });

  final int minClasses;
  final int? minMonths;
  final int? minClassesPerDegree;
  final bool requiresExam;

  BeltConfigData copyWith({
    int? minClasses,
    int? minMonths,
    int? minClassesPerDegree,
    bool? requiresExam,
  }) {
    return BeltConfigData(
      minClasses: minClasses ?? this.minClasses,
      minMonths: minMonths ?? this.minMonths,
      minClassesPerDegree: minClassesPerDegree ?? this.minClassesPerDegree,
      requiresExam: requiresExam ?? this.requiresExam,
    );
  }
}

