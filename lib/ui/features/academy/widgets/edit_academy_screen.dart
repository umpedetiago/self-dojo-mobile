import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:self_dojo_mobile/core/theme/app_colors.dart';
import 'package:self_dojo_mobile/data/repositories/academy_repository.dart';
import 'package:self_dojo_mobile/data/repositories/profile_repository.dart';
import 'package:self_dojo_mobile/domain/models/academy/academy.dart';
import 'package:self_dojo_mobile/ui/features/academy/view_models/academy_viewmodel.dart';
import 'package:self_dojo_mobile/ui/features/auth/view_models/auth_viewmodel.dart';
import 'package:self_dojo_mobile/ui/features/auth/widgets/auth_text_field.dart';

/// Edição de dados da academia (owner).
class EditAcademyScreen extends StatelessWidget {
  const EditAcademyScreen({super.key, required this.academyId});

  final String academyId;

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
        academyId: academyId,
      ),
      child: const _EditAcademyContent(),
    );
  }
}

class _EditAcademyContent extends StatefulWidget {
  const _EditAcademyContent();

  @override
  State<_EditAcademyContent> createState() => _EditAcademyContentState();
}

class _EditAcademyContentState extends State<_EditAcademyContent> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _logoUrlController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _websiteController;

  bool _initialized = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _logoUrlController = TextEditingController();
    _addressController = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _websiteController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _logoUrlController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  void _initFromAcademy(Academy academy) {
    if (_initialized) return;
    _nameController.text = academy.name;
    _descriptionController.text = academy.description ?? '';
    _logoUrlController.text = academy.logoUrl ?? '';
    _addressController.text = academy.address ?? '';
    _cityController.text = academy.city ?? '';
    _stateController.text = academy.state ?? '';
    _phoneController.text = academy.phone ?? '';
    _emailController.text = academy.email ?? '';
    _websiteController.text = academy.website ?? '';
    _initialized = true;
  }

  Future<void> _save(AcademyViewModel viewModel) async {
    if (!_formKey.currentState!.validate()) return;
    if (viewModel.academy.isEmpty) return;

    setState(() => _isSaving = true);
    final updated = viewModel.academy.copyWith(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      logoUrl: _logoUrlController.text.trim().isEmpty
          ? null
          : _logoUrlController.text.trim(),
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
      state:
          _stateController.text.trim().isEmpty ? null : _stateController.text.trim(),
      phone:
          _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      email:
          _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      website: _websiteController.text.trim().isEmpty
          ? null
          : _websiteController.text.trim(),
    );

    final result = await viewModel.updateAcademy.execute(updated);
    setState(() => _isSaving = false);

    result.fold(
      onSuccess: (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Academia atualizada com sucesso'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      },
      onFailure: (failure) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: AppColors.error,
          ),
        );
      },
    );
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

    if (!viewModel.hasAcademy) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Editar Academia'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: Text('Academia não encontrada'),
        ),
      );
    }

    final academy = viewModel.academy;
    _initFromAcademy(academy);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Academia'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : () => _save(viewModel),
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Salvar'),
          ),
        ],
      ),
      body: Container(
        decoration: _backgroundDecoration,
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                AuthTextField(
                  controller: _nameController,
                  label: 'Nome',
                  prefixIcon: Icons.badge,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
                ),
                const SizedBox(height: 12),
                AuthTextField(
                  controller: _descriptionController,
                  label: 'Descrição',
                  prefixIcon: Icons.description,
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                AuthTextField(
                  controller: _logoUrlController,
                  label: 'Logo URL',
                  prefixIcon: Icons.image,
                ),
                const SizedBox(height: 12),
                AuthTextField(
                  controller: _addressController,
                  label: 'Endereço',
                  prefixIcon: Icons.location_on,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AuthTextField(
                        controller: _cityController,
                        label: 'Cidade',
                        prefixIcon: Icons.location_city,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AuthTextField(
                        controller: _stateController,
                        label: 'Estado',
                        prefixIcon: Icons.map,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AuthTextField(
                  controller: _phoneController,
                  label: 'Telefone',
                  prefixIcon: Icons.phone,
                ),
                const SizedBox(height: 12),
                AuthTextField(
                  controller: _emailController,
                  label: 'Email',
                  prefixIcon: Icons.email,
                ),
                const SizedBox(height: 12),
                AuthTextField(
                  controller: _websiteController,
                  label: 'Website',
                  prefixIcon: Icons.public,
                ),
              ],
            ),
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

