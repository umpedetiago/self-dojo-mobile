import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:self_dojo_mobile/core/theme/app_colors.dart';
import 'package:self_dojo_mobile/core/ui/components/app_role_toggle.dart';
import 'package:self_dojo_mobile/data/repositories/auth_repository.dart';
import 'package:self_dojo_mobile/data/services/profile_service.dart';
import 'package:self_dojo_mobile/domain/models/academy/user_role.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/martial_art.dart';
import 'package:self_dojo_mobile/domain/models/user_profile.dart';
import 'package:self_dojo_mobile/ui/features/auth/view_models/register_viewmodel.dart';
import 'package:self_dojo_mobile/ui/features/auth/widgets/auth_text_field.dart';

/// Tela de Cadastro simplificada
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

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
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
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),

                      // Header
                      _buildHeader(),

                      const SizedBox(height: 16),

                      // Seleção de Role
                      _buildRoleSelector(viewModel),

                      const SizedBox(height: 16),

                      // Seleção de Modalidade (apenas se não for owner)
                      if (viewModel.isMartialArtRequired) ...[
                        _buildMartialArtSelector(viewModel),
                        const SizedBox(height: 16),
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

                      const SizedBox(height: 16),

                      // Botão de cadastro
                      _buildRegisterButton(viewModel),

                      const SizedBox(height: 16),

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
              Icons.arrow_back,
              color: AppColors.textPrimaryDark,
            ),
          ),
          const Expanded(
            child: Text(
              'Create Your Account',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryDark,
              ),
            ),
          ),
          const SizedBox(width: 48), // Balancear o botão de voltar
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Join Self Dojo',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select your role and enter your details to get started on your martial arts journey.',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondaryDark,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSelector(RegisterViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'I am a...',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 12),
          AppRoleToggle(
            selectedRole: viewModel.selectedRole,
            onRoleChanged: viewModel.setSelectedRole,
          ),
        ],
      ),
    );
  }

  Widget _buildMartialArtSelector(RegisterViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Primary Interest',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryDark,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariantDark.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: viewModel.selectedMartialArt == null
                    ? AppColors.textTertiaryDark.withValues(alpha: 0.3)
                    : AppColors.primary.withValues(alpha: 0.5),
                width: 1,
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
                        'Select a martial art',
                        style: TextStyle(
                          color: AppColors.textTertiaryDark.withValues(alpha: 0.6),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                isExpanded: true,
                icon: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Icon(
                    Icons.expand_more,
                    color: AppColors.textSecondaryDark.withValues(alpha: 0.7),
                  ),
                ),
                dropdownColor: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                style: const TextStyle(
                  color: AppColors.textPrimaryDark,
                  fontSize: 16,
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
      ),
    );
  }

  Widget _buildForm(RegisterViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          AuthTextField(
            controller: _nameController,
            focusNode: _nameFocus,
            label: 'Full Name',
            hint: 'Enter your full name',
            textInputAction: TextInputAction.next,
            prefixIcon: Icons.person,
            onChanged: viewModel.setName,
            onSubmitted: (_) => _emailFocus.requestFocus(),
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _emailController,
            focusNode: _emailFocus,
            label: 'Email Address',
            hint: 'name@example.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            prefixIcon: Icons.mail,
            onChanged: viewModel.setEmail,
            onSubmitted: (_) => _passwordFocus.requestFocus(),
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _passwordController,
            focusNode: _passwordFocus,
            label: 'Password',
            hint: 'Create a strong password',
            obscureText: viewModel.obscurePassword,
            textInputAction: TextInputAction.done,
            prefixIcon: Icons.lock,
            suffixIcon: viewModel.obscurePassword
                ? Icons.visibility_off
                : Icons.visibility,
            onSuffixTap: viewModel.togglePasswordVisibility,
            onChanged: viewModel.setPassword,
            onSubmitted: (_) => _handleRegister(viewModel),
            errorText: viewModel.passwordError,
          ),
        ],
      ),
    );
  }

  Widget _buildError(RegisterViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
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
      ),
    );
  }

  Widget _buildTermsCheckbox(RegisterViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
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
                  color: AppColors.textSecondaryDark,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(text: 'I agree to the '),
                  TextSpan(
                    text: 'Terms of Service',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        // TODO: Abrir termos de uso
                      },
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        // TODO: Abrir política de privacidade
                      },
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton(RegisterViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListenableBuilder(
        listenable: viewModel.createFirebaseAccount,
        builder: (context, _) {
          final isLoading = viewModel.createFirebaseAccount.running ||
              viewModel.createSupabaseProfile.running;

          return SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: viewModel.isFormValid && !isLoading
                  ? () => _handleRegister(viewModel)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                shadowColor: AppColors.primary.withValues(alpha: 0.2),
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
                      'Create Account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoginLink() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Already have an account? ',
            style: TextStyle(
              color: AppColors.textSecondaryDark,
              fontSize: 14,
            ),
          ),
          GestureDetector(
            onTap: () => context.pop(),
            child: const Text(
              'Log In',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRegister(RegisterViewModel viewModel) async {
    FocusScope.of(context).unfocus();

    // ETAPA 1: Criar conta no Firebase (autenticação)
    final firebaseResult = await viewModel.createFirebaseAccount.execute();
    if (!mounted) return;

    if (!firebaseResult.isSuccess) {
      // Erro já é mostrado no widget de erro pelo ViewModel
      return;
    }

    final user = viewModel.createFirebaseAccount.data!;
    final profileService = context.read<ProfileService>();

    // ETAPA 2: Criar perfil completo no Supabase (banco de dados)
    final profileResult = await viewModel.createSupabaseProfile.execute(user);
    if (!mounted) return;

    if (!profileResult.isSuccess) {
      // Se falhar ao criar perfil no Supabase, ainda assim atualiza em memória
      // para que o usuário possa usar o app
      final profile = UserProfile(
        id: user.id,
        email: user.email,
        displayName: user.displayName ?? viewModel.name.trim(),
        role: viewModel.selectedRole,
        martialArtType: viewModel.selectedMartialArt ??
            (viewModel.selectedRole == UserRole.owner ? null : MartialArtType.jiuJitsu),
        createdAt: DateTime.now(),
      );
      profileService.setProfileAfterRegistration(profile);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Conta criada! Mas houve um problema ao salvar seu perfil. '
            'Alguns dados podem não aparecer corretamente.',
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      context.go('/home');
      return;
    }

    // Sucesso nas duas etapas: atualiza ProfileService em memória primeiro
    final displayName = user.displayName?.isNotEmpty == true 
        ? user.displayName 
        : (viewModel.name.trim().isEmpty ? null : viewModel.name.trim());
    
    final profile = UserProfile(
      id: user.id,
      email: user.email,
      displayName: displayName,
      role: viewModel.selectedRole,
      martialArtType: viewModel.selectedMartialArt ??
          (viewModel.selectedRole == UserRole.owner ? null : MartialArtType.jiuJitsu),
      createdAt: DateTime.now(),
    );
    
    debugPrint('[RegisterScreen] Perfil criado - displayName: ${profile.displayName}, martialArtType: ${profile.martialArtType}');
    
    // Atualiza em memória para garantir que os dados apareçam imediatamente
    profileService.setProfileAfterRegistration(profile);

    // Pequeno delay para garantir que o Supabase processou o INSERT
    await Future.delayed(const Duration(milliseconds: 500));

    // Agora inicializa do Supabase para garantir sincronização
    // Mas como já temos o perfil em memória, se o Supabase ainda não tiver
    // os dados, o init vai preservar o que já está em memória
    await profileService.init(
      user.id,
      email: user.email,
      displayName: profile.displayName,
      photoUrl: user.photoUrl,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Conta criada! Verifique seu email para confirmar.',
        ),
        backgroundColor: AppColors.success,
      ),
    );

    // Só navega para Home quando o ProfileService estiver completamente inicializado
    context.go('/home');
  }
}
