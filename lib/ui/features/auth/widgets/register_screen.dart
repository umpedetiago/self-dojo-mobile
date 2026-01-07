import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:self_dojo_mobile/core/theme/app_colors.dart';
import 'package:self_dojo_mobile/data/repositories/auth_repository.dart';
import 'package:self_dojo_mobile/domain/models/academy/user_role.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/martial_art.dart';
import 'package:self_dojo_mobile/ui/features/auth/view_models/register_viewmodel.dart';
import 'package:self_dojo_mobile/ui/features/auth/widgets/auth_text_field.dart';

/// Tela de Cadastro
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => RegisterViewModel(
        authRepository: ctx.read<AuthRepository>(),
      ),
      child: const _RegisterContent(),
    );
  }
}

class _RegisterContent extends StatefulWidget {
  const _RegisterContent();

  @override
  State<_RegisterContent> createState() => _RegisterContentState();
}

class _RegisterContentState extends State<_RegisterContent> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<RegisterViewModel>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1a1a3e),
              AppColors.backgroundDark,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // AppBar customizada
              _buildAppBar(),

              // Conteúdo scrollável
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),

                      // Header
                      _buildHeader(),

                      const SizedBox(height: 24),

                      // Seleção de Role
                      _buildRoleSelector(viewModel),

                      const SizedBox(height: 24),

                      // Seleção de Modalidade (apenas se não for owner)
                      if (viewModel.isMartialArtRequired) ...[
                        _buildMartialArtSelector(viewModel),
                        const SizedBox(height: 24),
                      ],

                      // Formulário
                      _buildForm(viewModel),

                      const SizedBox(height: 16),

                      // Erro
                      if (viewModel.errorMessage != null)
                        _buildError(viewModel),

                      const SizedBox(height: 16),

                      // Termos de uso
                      _buildTermsCheckbox(viewModel),

                      const SizedBox(height: 24),

                      // Botão de cadastro
                      _buildRegisterButton(viewModel),

                      const SizedBox(height: 24),

                      // Já tem conta
                      _buildLoginLink(),

                      const SizedBox(height: 32),
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

  Widget _buildAppBar() {
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
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (bounds) =>
              AppColors.primaryGradient.createShader(bounds),
          child: const Text(
            'Criar conta',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Comece sua jornada de autodesenvolvimento',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondaryDark.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSelector(RegisterViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Eu sou:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimaryDark.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: RegisterViewModel.availableRoles.map((role) {
            final isSelected = viewModel.selectedRole == role;
            return _RoleChip(
              role: role,
              isSelected: isSelected,
              onTap: () => viewModel.setSelectedRole(role),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMartialArtSelector(RegisterViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Modalidade:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimaryDark.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceVariantDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: viewModel.selectedMartialArt == null
                  ? AppColors.textTertiaryDark.withValues(alpha: 0.3)
                  : AppColors.primary.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<MartialArtType>(
              value: viewModel.selectedMartialArt,
              hint: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.sports_martial_arts,
                      color: AppColors.textTertiaryDark.withValues(alpha: 0.6),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Selecione sua modalidade',
                      style: TextStyle(
                        color: AppColors.textTertiaryDark.withValues(alpha: 0.6),
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              isExpanded: true,
              icon: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textSecondaryDark.withValues(alpha: 0.7),
                ),
              ),
              dropdownColor: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              style: const TextStyle(
                color: AppColors.textPrimaryDark,
                fontSize: 15,
              ),
              items: RegisterViewModel.availableMartialArts.map((art) {
                return DropdownMenuItem<MartialArtType>(
                  value: art.type,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(
                          art.icon,
                          color: art.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(art.name),
                      ],
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) => viewModel.setSelectedMartialArt(value),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForm(RegisterViewModel viewModel) {
    return Column(
      children: [
        AuthTextField(
          controller: _nameController,
          focusNode: _nameFocus,
          label: 'Nome completo',
          hint: 'Seu nome',
          textInputAction: TextInputAction.next,
          prefixIcon: Icons.person_outline,
          onChanged: viewModel.setName,
          onSubmitted: (_) => _emailFocus.requestFocus(),
        ),
        const SizedBox(height: 16),
        AuthTextField(
          controller: _emailController,
          focusNode: _emailFocus,
          label: 'Email',
          hint: 'seu@email.com',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          prefixIcon: Icons.email_outlined,
          onChanged: viewModel.setEmail,
          onSubmitted: (_) => _passwordFocus.requestFocus(),
        ),
        const SizedBox(height: 16),
        AuthTextField(
          controller: _passwordController,
          focusNode: _passwordFocus,
          label: 'Senha',
          hint: 'Mínimo 6 caracteres',
          obscureText: viewModel.obscurePassword,
          textInputAction: TextInputAction.next,
          prefixIcon: Icons.lock_outline,
          suffixIcon: viewModel.obscurePassword
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          onSuffixTap: viewModel.togglePasswordVisibility,
          onChanged: viewModel.setPassword,
          onSubmitted: (_) => _confirmPasswordFocus.requestFocus(),
          errorText: viewModel.passwordError,
        ),
        const SizedBox(height: 16),
        AuthTextField(
          controller: _confirmPasswordController,
          focusNode: _confirmPasswordFocus,
          label: 'Confirmar senha',
          hint: 'Repita a senha',
          obscureText: viewModel.obscureConfirmPassword,
          prefixIcon: Icons.lock_outline,
          suffixIcon: viewModel.obscureConfirmPassword
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          onSuffixTap: viewModel.toggleConfirmPasswordVisibility,
          onChanged: viewModel.setConfirmPassword,
          onSubmitted: (_) => _handleRegister(viewModel),
          errorText: viewModel.confirmPasswordError,
        ),
      ],
    );
  }

  Widget _buildError(RegisterViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: AppColors.error.withValues(alpha: 0.8),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              viewModel.errorMessage!,
              style: TextStyle(
                color: AppColors.error.withValues(alpha: 0.9),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsCheckbox(RegisterViewModel viewModel) {
    return GestureDetector(
      onTap: viewModel.toggleAcceptedTerms,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: viewModel.acceptedTerms,
              onChanged: (_) => viewModel.toggleAcceptedTerms(),
              activeColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              side: BorderSide(
                color: AppColors.textTertiaryDark.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondaryDark.withValues(alpha: 0.8),
                  height: 1.4,
                ),
                children: [
                  const TextSpan(text: 'Li e concordo com os '),
                  TextSpan(
                    text: 'Termos de Uso',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        // TODO: Abrir termos de uso
                      },
                  ),
                  const TextSpan(text: ' e '),
                  TextSpan(
                    text: 'Política de Privacidade',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        // TODO: Abrir política de privacidade
                      },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton(RegisterViewModel viewModel) {
    return ListenableBuilder(
      listenable: viewModel.register,
      builder: (context, _) {
        final isLoading = viewModel.register.running;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 56,
          child: ElevatedButton(
            onPressed:
                viewModel.isFormValid && !isLoading
                    ? () => _handleRegister(viewModel)
                    : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Criar conta',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Já tem uma conta? ',
          style: TextStyle(
            color: AppColors.textSecondaryDark.withValues(alpha: 0.8),
            fontSize: 14,
          ),
        ),
        GestureDetector(
          onTap: () => context.pop(),
          child: const Text(
            'Entrar',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleRegister(RegisterViewModel viewModel) async {
    FocusScope.of(context).unfocus();
    final result = await viewModel.register.execute();

    if (mounted) {
      result.fold(
        onSuccess: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Conta criada! Verifique seu email para confirmar.',
              ),
              backgroundColor: AppColors.success,
            ),
          );
        },
        onFailure: (_) {
          // Erro já é mostrado no widget de erro
        },
      );
    }
  }
}

/// Chip de seleção de role
class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.role,
    required this.isSelected,
    required this.onTap,
  });

  final UserRole role;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected ? null : AppColors.surfaceVariantDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : AppColors.textTertiaryDark.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getIconForRole(role),
              size: 20,
              color: isSelected
                  ? Colors.white
                  : AppColors.textSecondaryDark.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 8),
            Text(
              role.displayName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : AppColors.textSecondaryDark.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForRole(UserRole role) {
    switch (role) {
      case UserRole.student:
        return Icons.school_outlined;
      case UserRole.instructor:
        return Icons.sports_martial_arts;
      case UserRole.teacher:
        return Icons.person_outline;
      case UserRole.modalityMaster:
        return Icons.workspace_premium_outlined;
      case UserRole.owner:
        return Icons.business_outlined;
    }
  }
}

