import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:self_dojo_mobile/core/theme/app_colors.dart';
import 'package:self_dojo_mobile/data/repositories/profile_repository.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/martial_art.dart';
import 'package:self_dojo_mobile/domain/models/user_profile.dart';
import 'package:self_dojo_mobile/ui/features/auth/view_models/auth_viewmodel.dart';
import 'package:self_dojo_mobile/ui/features/auth/widgets/auth_text_field.dart';
import 'package:self_dojo_mobile/ui/features/profile/view_models/profile_viewmodel.dart';

/// Tela de edição de perfil
class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

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
      create: (ctx) => ProfileViewModel(
        profileRepository: ctx.read<ProfileRepository>(),
        userId: userId,
        authUser: authViewModel.user,
      ),
      child: const _EditProfileContent(),
    );
  }
}

class _EditProfileContent extends StatefulWidget {
  const _EditProfileContent();

  @override
  State<_EditProfileContent> createState() => _EditProfileContentState();
}

class _EditProfileContentState extends State<_EditProfileContent> {
  late TextEditingController _nameController;
  late TextEditingController _academyController;
  late TextEditingController _instructorController;
  late TextEditingController _weightController;

  MartialArtType? _selectedMartialArt;
  File? _selectedPhoto;
  bool _isSaving = false;
  bool _initialized = false;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _academyController = TextEditingController();
    _instructorController = TextEditingController();
    _weightController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _academyController.dispose();
    _instructorController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _initializeControllers(UserProfile profile) {
    if (_initialized) return;

    _nameController.text = profile.displayName ?? '';
    _academyController.text = profile.academyName ?? '';
    _instructorController.text = profile.instructorName ?? '';
    _weightController.text = profile.weightCategory ?? '';
    _selectedMartialArt = profile.martialArtType;
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ProfileViewModel>();
    final profile = viewModel.profile;

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

    _initializeControllers(profile);

    return Scaffold(
      body: Container(
        decoration: _backgroundDecoration,
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              _buildAppBar(context),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Foto de perfil
                      _buildPhotoSection(profile),
                      const SizedBox(height: 32),

                      // Dados pessoais
                      _buildSectionTitle('Dados Pessoais'),
                      const SizedBox(height: 16),
                      AuthTextField(
                        controller: _nameController,
                        label: 'Nome completo',
                        hint: 'Seu nome',
                        prefixIcon: Icons.person_outline,
                      ),
                      const SizedBox(height: 24),

                      // Arte marcial
                      _buildSectionTitle('Arte Marcial'),
                      const SizedBox(height: 16),
                      _buildMartialArtSelector(),
                      const SizedBox(height: 24),

                      // Academia
                      _buildSectionTitle('Academia'),
                      const SizedBox(height: 16),
                      AuthTextField(
                        controller: _academyController,
                        label: 'Academia / Dojô',
                        hint: 'Nome da sua academia',
                        prefixIcon: Icons.home_work_outlined,
                      ),
                      const SizedBox(height: 16),
                      AuthTextField(
                        controller: _instructorController,
                        label: 'Professor / Mestre',
                        hint: 'Nome do seu professor',
                        prefixIcon: Icons.school_outlined,
                      ),
                      const SizedBox(height: 24),

                      // Categoria
                      _buildSectionTitle('Categoria'),
                      const SizedBox(height: 16),
                      AuthTextField(
                        controller: _weightController,
                        label: 'Categoria de Peso',
                        hint: 'Ex: Leve, Médio, Pesado',
                        prefixIcon: Icons.monitor_weight_outlined,
                      ),
                      const SizedBox(height: 40),

                      // Botão salvar
                      _buildSaveButton(viewModel, profile),
                      const SizedBox(height: 20),
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
              'Editar Perfil',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryDark,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48), // Para balancear o botão de voltar
        ],
      ),
    );
  }

  Widget _buildPhotoSection(UserProfile profile) {
    final hasPhoto = profile.photoUrl != null || _selectedPhoto != null;

    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: !hasPhoto ? AppColors.primaryGradient : null,
                image: _selectedPhoto != null
                    ? DecorationImage(
                        image: FileImage(_selectedPhoto!),
                        fit: BoxFit.cover,
                      )
                    : profile.photoUrl != null
                        ? DecorationImage(
                            image: NetworkImage(profile.photoUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: !hasPhoto
                  ? const Icon(
                      Icons.person,
                      size: 48,
                      color: Colors.white,
                    )
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.backgroundDark,
                    width: 3,
                  ),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimaryDark,
      ),
    );
  }

  Widget _buildMartialArtSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariantDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.surfaceVariantDark.withValues(alpha: 0.3),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<MartialArtType>(
          value: _selectedMartialArt,
          isExpanded: true,
          dropdownColor: AppColors.surfaceDark,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
          items: MartialArtsConfig.all.map((art) {
            return DropdownMenuItem(
              value: art.type,
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: art.primaryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      art.icon,
                      color: art.primaryColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    art.name,
                    style: const TextStyle(
                      color: AppColors.textPrimaryDark,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedMartialArt = value;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildSaveButton(ProfileViewModel viewModel, UserProfile profile) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isSaving ? null : () => _saveProfile(viewModel, profile),
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
                'Salvar Alterações',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Escolher Foto',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryDark,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.camera_alt, color: AppColors.primary),
              ),
              title: const Text(
                'Câmera',
                style: TextStyle(color: AppColors.textPrimaryDark),
              ),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_library, color: AppColors.secondary),
              ),
              title: const Text(
                'Galeria',
                style: TextStyle(color: AppColors.textPrimaryDark),
              ),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );

    if (picked != null) {
      setState(() {
        _selectedPhoto = File(picked.path);
      });
    }
  }

  Future<void> _saveProfile(
      ProfileViewModel viewModel, UserProfile profile) async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Atualiza foto se selecionada
      if (_selectedPhoto != null) {
        await viewModel.updatePhoto.execute(_selectedPhoto!);
      }

      // Atualiza perfil
      final updatedProfile = profile.copyWith(
        displayName: _nameController.text.trim(),
        academyName: _academyController.text.trim(),
        instructorName: _instructorController.text.trim(),
        weightCategory: _weightController.text.trim(),
        martialArtType: _selectedMartialArt,
      );

      final result = await viewModel.updateProfile.execute(updatedProfile);

      if (mounted) {
        result.fold(
          onSuccess: (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Perfil atualizado com sucesso!'),
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
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}

