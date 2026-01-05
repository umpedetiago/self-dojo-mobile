import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:self_dojo_mobile/core/theme/app_colors.dart';
import 'package:self_dojo_mobile/data/repositories/auth_repository.dart';
import 'package:self_dojo_mobile/ui/features/auth/view_models/login_viewmodel.dart';
import 'package:self_dojo_mobile/ui/features/auth/widgets/auth_text_field.dart';

/// Tela de Login
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => LoginViewModel(
        authRepository: ctx.read<AuthRepository>(),
      ),
      child: const _LoginContent(),
    );
  }
}

class _LoginContent extends StatefulWidget {
  const _LoginContent();

  @override
  State<_LoginContent> createState() => _LoginContentState();
}

class _LoginContentState extends State<_LoginContent> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LoginViewModel>();

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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),

                // Logo e título
                _buildHeader(),

                const SizedBox(height: 48),

                // Formulário
                _buildForm(viewModel),

                const SizedBox(height: 16),

                // Erro
                if (viewModel.errorMessage != null) _buildError(viewModel),

                const SizedBox(height: 24),

                // Botão de login
                _buildLoginButton(viewModel),

                const SizedBox(height: 16),

                // Esqueci minha senha
                _buildForgotPassword(viewModel),

                const SizedBox(height: 48),

                // Divisor
                _buildDivider(),

                const SizedBox(height: 24),

                // Criar conta
                _buildCreateAccount(),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'SD',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Bem-vindo de volta!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimaryDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Entre para continuar sua jornada',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondaryDark.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildForm(LoginViewModel viewModel) {
    return Column(
      children: [
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
          hint: '••••••••',
          obscureText: viewModel.obscurePassword,
          prefixIcon: Icons.lock_outline,
          suffixIcon: viewModel.obscurePassword
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          onSuffixTap: viewModel.togglePasswordVisibility,
          onChanged: viewModel.setPassword,
          onSubmitted: (_) => _handleLogin(viewModel),
        ),
      ],
    );
  }

  Widget _buildError(LoginViewModel viewModel) {
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

  Widget _buildLoginButton(LoginViewModel viewModel) {
    return ListenableBuilder(
      listenable: viewModel.login,
      builder: (context, _) {
        final isLoading = viewModel.login.running;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 56,
          child: ElevatedButton(
            onPressed:
                viewModel.isFormValid && !isLoading
                    ? () => _handleLogin(viewModel)
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
                    'Entrar',
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

  Widget _buildForgotPassword(LoginViewModel viewModel) {
    return TextButton(
      onPressed: () => _showForgotPasswordDialog(viewModel),
      child: Text(
        'Esqueceu sua senha?',
        style: TextStyle(
          color: AppColors.textSecondaryDark.withValues(alpha: 0.8),
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: AppColors.textTertiaryDark.withValues(alpha: 0.3),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'ou',
            style: TextStyle(
              color: AppColors.textTertiaryDark.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: AppColors.textTertiaryDark.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateAccount() {
    return OutlinedButton(
      onPressed: () => context.push('/register'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: BorderSide(
          color: AppColors.primary.withValues(alpha: 0.5),
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: const Text(
        'Criar uma conta',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Future<void> _handleLogin(LoginViewModel viewModel) async {
    FocusScope.of(context).unfocus();
    await viewModel.login.execute();
  }

  void _showForgotPasswordDialog(LoginViewModel viewModel) {
    final emailController = TextEditingController(text: viewModel.email);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Recuperar senha'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Digite seu email para receber o link de recuperação de senha.',
              style: TextStyle(color: AppColors.textSecondaryDark),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ListenableBuilder(
            listenable: viewModel.forgotPassword,
            builder: (context, _) {
              return ElevatedButton(
                onPressed: viewModel.forgotPassword.running
                    ? null
                    : () async {
                        final result = await viewModel.forgotPassword
                            .execute(emailController.text);
                        if (context.mounted) {
                          Navigator.pop(context);
                          result.fold(
                            onSuccess: (_) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Email de recuperação enviado!',
                                  ),
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
                child: viewModel.forgotPassword.running
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Enviar'),
              );
            },
          ),
        ],
      ),
    );
  }
}

