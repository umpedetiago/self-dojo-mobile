import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:self_dojo_mobile/core/theme/app_colors.dart';
import 'package:self_dojo_mobile/data/repositories/academy_repository.dart';
import 'package:self_dojo_mobile/data/repositories/profile_repository.dart';
import 'package:self_dojo_mobile/domain/models/academy/subscription.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/martial_art.dart';
import 'package:self_dojo_mobile/ui/features/academy/view_models/academy_viewmodel.dart';
import 'package:self_dojo_mobile/ui/features/auth/view_models/auth_viewmodel.dart';
import 'package:self_dojo_mobile/ui/features/auth/widgets/auth_text_field.dart';

/// Tela para criar uma nova academia
class CreateAcademyScreen extends StatelessWidget {
  const CreateAcademyScreen({super.key});

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
      child: const _CreateAcademyContent(),
    );
  }
}

class _CreateAcademyContent extends StatefulWidget {
  const _CreateAcademyContent();

  @override
  State<_CreateAcademyContent> createState() => _CreateAcademyContentState();
}

class _CreateAcademyContentState extends State<_CreateAcademyContent> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  final Set<MartialArtType> _selectedModalities = {MartialArtType.jiuJitsu};
  bool _isCreating = false;
  int _currentStep = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AcademyViewModel>();

    // Se já tem academia, redireciona
    if (viewModel.hasAcademy) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/academy/manage');
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      body: Container(
        decoration: _backgroundDecoration,
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: Stepper(
                    currentStep: _currentStep,
                    onStepContinue: _onStepContinue,
                    onStepCancel: _onStepCancel,
                    controlsBuilder: _buildControls,
                    steps: [
                      _buildInfoStep(),
                      _buildModalitiesStep(),
                      _buildContactStep(),
                      _buildConfirmStep(),
                    ],
                  ),
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
          const Expanded(
            child: Text(
              'Criar Academia',
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

  Step _buildInfoStep() {
    return Step(
      title: const Text('Informações', style: TextStyle(color: AppColors.textPrimaryDark)),
      subtitle: const Text('Dados da academia', style: TextStyle(color: AppColors.textSecondaryDark)),
      isActive: _currentStep >= 0,
      state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      content: Column(
        children: [
          const SizedBox(height: 8),
          AuthTextField(
            controller: _nameController,
            label: 'Nome da Academia *',
            hint: 'Ex: Academia Luta & Arte',
            prefixIcon: Icons.business,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Nome é obrigatório';
              }
              if (value.length < 3) {
                return 'Nome deve ter pelo menos 3 caracteres';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _descriptionController,
            label: 'Descrição',
            hint: 'Descreva sua academia',
            prefixIcon: Icons.description,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Step _buildModalitiesStep() {
    return Step(
      title: const Text('Modalidades', style: TextStyle(color: AppColors.textPrimaryDark)),
      subtitle: Text(
        '${_selectedModalities.length} selecionada(s)',
        style: const TextStyle(color: AppColors.textSecondaryDark),
      ),
      isActive: _currentStep >= 1,
      state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selecione as artes marciais oferecidas:',
            style: TextStyle(color: AppColors.textSecondaryDark),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MartialArtsConfig.all.map((art) {
              final isSelected = _selectedModalities.contains(art.type);
              return FilterChip(
                label: Text(art.shortName),
                avatar: Icon(
                  art.icon,
                  size: 18,
                  color: isSelected ? Colors.white : art.primaryColor,
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedModalities.add(art.type);
                    } else if (_selectedModalities.length > 1) {
                      _selectedModalities.remove(art.type);
                    }
                  });
                },
                selectedColor: art.primaryColor,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimaryDark,
                ),
                backgroundColor: AppColors.surfaceVariantDark,
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No período de trial você pode adicionar até ${SubscriptionPlanConfig.defaults[SubscriptionPlan.pro]!.maxModalities} modalidades.',
                    style: const TextStyle(
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
    );
  }

  Step _buildContactStep() {
    return Step(
      title: const Text('Contato', style: TextStyle(color: AppColors.textPrimaryDark)),
      subtitle: const Text('Localização e contato', style: TextStyle(color: AppColors.textSecondaryDark)),
      isActive: _currentStep >= 2,
      state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      content: Column(
        children: [
          const SizedBox(height: 8),
          AuthTextField(
            controller: _addressController,
            label: 'Endereço',
            hint: 'Rua, número',
            prefixIcon: Icons.location_on,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: AuthTextField(
                  controller: _cityController,
                  label: 'Cidade',
                  hint: 'Cidade',
                  prefixIcon: Icons.location_city,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AuthTextField(
                  controller: _stateController,
                  label: 'UF',
                  hint: 'UF',
                  prefixIcon: Icons.map,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _phoneController,
            label: 'Telefone',
            hint: '(00) 00000-0000',
            prefixIcon: Icons.phone,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _emailController,
            label: 'Email da Academia',
            hint: 'contato@academia.com',
            prefixIcon: Icons.email,
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ),
    );
  }

  Step _buildConfirmStep() {
    return Step(
      title: const Text('Confirmar', style: TextStyle(color: AppColors.textPrimaryDark)),
      subtitle: const Text('Revise e confirme', style: TextStyle(color: AppColors.textSecondaryDark)),
      isActive: _currentStep >= 3,
      state: StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildConfirmItem('Nome', _nameController.text),
          _buildConfirmItem(
            'Modalidades',
            _selectedModalities
                .map((t) => MartialArtsConfig.getByType(t).shortName)
                .join(', '),
          ),
          if (_cityController.text.isNotEmpty)
            _buildConfirmItem('Localização',
                '${_cityController.text}${_stateController.text.isNotEmpty ? ' - ${_stateController.text}' : ''}'),
          if (_phoneController.text.isNotEmpty)
            _buildConfirmItem('Telefone', _phoneController.text),
          if (_emailController.text.isNotEmpty)
            _buildConfirmItem('Email', _emailController.text),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.card_giftcard, color: AppColors.success, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '🎉 Você terá 7 dias de trial gratuito para testar todas as funcionalidades!',
                    style: TextStyle(
                      color: AppColors.textPrimaryDark,
                      fontSize: 13,
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

  Widget _buildConfirmItem(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: AppColors.textSecondaryDark,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimaryDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(BuildContext context, ControlsDetails details) {
    final isLastStep = _currentStep == 3;

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Row(
        children: [
          if (_currentStep > 0)
            TextButton(
              onPressed: details.onStepCancel,
              child: const Text('Voltar'),
            ),
          const Spacer(),
          ElevatedButton(
            onPressed: _isCreating ? null : details.onStepContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: isLastStep ? AppColors.success : AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: _isCreating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    isLastStep ? 'Criar Academia' : 'Continuar',
                    style: const TextStyle(color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }

  void _onStepContinue() {
    if (_currentStep == 0) {
      // Valida nome
      if (_nameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Informe o nome da academia'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      _createAcademy();
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _createAcademy() async {
    if (_isCreating) return;

    setState(() => _isCreating = true);

    final viewModel = context.read<AcademyViewModel>();

    final result = await viewModel.createAcademy.execute(
      CreateAcademyParams(
        name: _nameController.text.trim(),
        modalities: _selectedModalities.toList(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        address: _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : null,
        city: _cityController.text.trim().isNotEmpty
            ? _cityController.text.trim()
            : null,
        state: _stateController.text.trim().isNotEmpty
            ? _stateController.text.trim()
            : null,
        phone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        email: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
      ),
    );

    if (!mounted) return;

    setState(() => _isCreating = false);

    result.fold(
      onSuccess: (academy) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Academia criada com sucesso!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/academy/manage');
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

