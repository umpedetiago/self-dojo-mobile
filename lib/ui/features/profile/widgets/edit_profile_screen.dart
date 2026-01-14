import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:self_dojo_mobile/core/theme/app_colors.dart';
import 'package:self_dojo_mobile/data/services/profile_service.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/belt.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/martial_art.dart';
import 'package:self_dojo_mobile/domain/models/user_profile.dart';
import 'package:self_dojo_mobile/ui/features/auth/widgets/auth_text_field.dart';

/// Tela de edição de perfil
class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _EditProfileContent();
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
  String? _selectedBeltId;
  int _selectedDegree = 0;
  bool _hasAparadores = false;
  File? _selectedPhoto;
  String? _uploadedPhotoUrl; // URL da foto após upload
  bool _isUploadingPhoto = false; // Indica se está fazendo upload
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
    _selectedBeltId = profile.graduation?.beltId;
    _selectedDegree = profile.graduation?.degree ?? 0;
    _hasAparadores = profile.graduation?.hasAparadores ?? false;
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final profileService = context.watch<ProfileService>();
    final profile = profileService.profile;

    if (profileService.isLoading) {
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

                      // Graduação (apenas para owners)
                      if (profile.isOwner) ...[
                        _buildSectionTitle('Minha Graduação'),
                        const SizedBox(height: 8),
                        Text(
                          'Como dono de academia, você pode definir sua própria graduação.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondaryDark.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildGraduationSelector(),
                        const SizedBox(height: 24),
                      ],

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
                      _buildSaveButton(profileService, profile),
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
    final profileService = context.watch<ProfileService>();
    final hasPhoto = profile.photoUrl != null || 
                     _uploadedPhotoUrl != null || 
                     _selectedPhoto != null;

    return Center(
      child: GestureDetector(
        onTap: () => _pickImage(profileService),
        child: Stack(
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: !hasPhoto ? AppColors.primaryGradient : null,
                image: _uploadedPhotoUrl != null
                    ? DecorationImage(
                        image: NetworkImage(_uploadedPhotoUrl!),
                        fit: BoxFit.cover,
                      )
                    : _selectedPhoto != null
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
              child: _isUploadingPhoto
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : !hasPhoto
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
                // Reset graduação quando muda a arte marcial
                _selectedBeltId = null;
                _selectedDegree = 0;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildGraduationSelector() {
    if (_selectedMartialArt == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariantDark.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Selecione uma arte marcial primeiro',
          style: TextStyle(
            color: AppColors.textTertiaryDark.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    final martialArt = MartialArtsConfig.getByType(_selectedMartialArt!);
    final belts = martialArt.belts;
    final selectedBelt = _selectedBeltId != null
        ? martialArt.getBeltById(_selectedBeltId!)
        : null;

    return Column(
      children: [
        // Seletor de Faixa
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariantDark.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selectedBelt != null
                  ? selectedBelt.color.withValues(alpha: 0.5)
                  : AppColors.surfaceVariantDark.withValues(alpha: 0.3),
              width: selectedBelt != null ? 2 : 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedBeltId,
              hint: const Text(
                'Selecione sua faixa',
                style: TextStyle(color: AppColors.textTertiaryDark),
              ),
              isExpanded: true,
              dropdownColor: AppColors.surfaceDark,
              icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
              items: belts.map((belt) {
                return DropdownMenuItem(
                  value: belt.id,
                  child: Row(
                    children: [
                      // Mini representação da faixa
                      _buildMiniBeltPreview(belt),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          belt.name,
                          style: const TextStyle(
                            color: AppColors.textPrimaryDark,
                          ),
                        ),
                      ),
                      if (belt.maxDegrees > 0)
                        Text(
                          '(${belt.maxDegrees} graus)',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiaryDark.withValues(alpha: 0.7),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedBeltId = value;
                  _selectedDegree = 0; // Reset grau quando muda faixa
                });
              },
            ),
          ),
        ),

        // Seletor de Grau (se a faixa tiver graus)
        if (selectedBelt != null && selectedBelt.maxDegrees > 0) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariantDark.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.surfaceVariantDark.withValues(alpha: 0.3),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedDegree,
                isExpanded: true,
                dropdownColor: AppColors.surfaceDark,
                icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
                items: List.generate(selectedBelt.maxDegrees + 1, (index) {
                  return DropdownMenuItem(
                    value: index,
                    child: Row(
                      children: [
                        if (index > 0) ...[
                          ...List.generate(
                            index,
                            (_) => Container(
                              width: 8,
                              height: 20,
                              margin: const EdgeInsets.only(right: 4),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          index == 0 ? 'Sem grau' : '$index° grau',
                          style: const TextStyle(
                            color: AppColors.textPrimaryDark,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedDegree = value;
                    });
                  }
                },
              ),
            ),
          ),
        ],

        // Checkbox de aparadores (apenas para faixa preta sem graus)
        if (selectedBelt != null && 
            selectedBelt.tipColor != null && 
            _selectedDegree == 0) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariantDark.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.surfaceVariantDark.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: _hasAparadores,
                  onChanged: (value) {
                    setState(() {
                      _hasAparadores = value ?? false;
                    });
                  },
                  activeColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.textSecondaryDark),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _hasAparadores = !_hasAparadores;
                      });
                    },
                    child: const Text(
                      'Tenho aparadores na faixa',
                      style: TextStyle(
                        color: AppColors.textPrimaryDark,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSaveButton(ProfileService profileService, UserProfile profile) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isSaving ? null : () => _saveProfile(profileService, profile),
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

  Future<void> _pickImage(ProfileService profileService) async {
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
      final photoFile = File(picked.path);
      setState(() {
        _selectedPhoto = photoFile;
        _uploadedPhotoUrl = null; // Reseta URL anterior
        _isUploadingPhoto = true;
      });

      // Faz upload imediatamente após selecionar a imagem
      await _uploadPhoto(profileService);
    }
  }

  /// Faz upload da foto selecionada
  Future<void> _uploadPhoto(ProfileService profileService) async {
    if (_selectedPhoto == null) return;

    final result = await profileService.updatePhoto(_selectedPhoto!);
    
    setState(() {
      _isUploadingPhoto = false;
    });

    result.fold(
      onSuccess: (url) {
        setState(() {
          _uploadedPhotoUrl = url;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto carregada com sucesso!'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      onFailure: (failure) {
        setState(() {
          _selectedPhoto = null; // Remove foto se upload falhar
          _uploadedPhotoUrl = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao fazer upload da foto: ${failure.message}'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      },
    );
  }

  Future<void> _saveProfile(
      ProfileService profileService, UserProfile profile) async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Se há foto selecionada mas ainda não foi feito upload, faz upload agora
      if (_selectedPhoto != null && _uploadedPhotoUrl == null && !_isUploadingPhoto) {
        await _uploadPhoto(profileService);
        // Se o upload falhou, não continua salvando
        if (_uploadedPhotoUrl == null) {
          setState(() {
            _isSaving = false;
          });
          return;
        }
      }

      // Prepara graduação se owner e faixa selecionada
      UserGraduation? graduation = profile.graduation;
      if (profile.isOwner && _selectedBeltId != null) {
        graduation = UserGraduation(
          beltId: _selectedBeltId!,
          degree: _selectedDegree,
          promotionDate: DateTime.now(),
          classesAtCurrentBelt: profile.graduation?.classesAtCurrentBelt ?? 0,
          // hasAparadores só é relevante quando graus = 0, senão sempre tem
          hasAparadores: _selectedDegree == 0 ? _hasAparadores : null,
        );
      }

      // Atualiza perfil
      // Prioridade: _uploadedPhotoUrl > profile.photoUrl (do ProfileService que já foi atualizado)
      final photoUrlToSave = _uploadedPhotoUrl ?? profileService.profile.photoUrl;
      
      debugPrint('[EditProfileScreen] ===== Salvando Perfil =====');
      debugPrint('[EditProfileScreen] _uploadedPhotoUrl: $_uploadedPhotoUrl');
      debugPrint('[EditProfileScreen] profile.photoUrl (original): ${profile.photoUrl}');
      debugPrint('[EditProfileScreen] profileService.profile.photoUrl: ${profileService.profile.photoUrl}');
      debugPrint('[EditProfileScreen] photoUrlToSave: $photoUrlToSave');
      
      // Sempre inclui photoUrl no copyWith se tiver valor
      // O copyWith usa photoUrl ?? this.photoUrl, então se passar null, mantém o atual
      final updatedProfile = profile.copyWith(
        displayName: _nameController.text.trim(),
        academyName: _academyController.text.trim(),
        instructorName: _instructorController.text.trim(),
        weightCategory: _weightController.text.trim(),
        martialArtType: _selectedMartialArt,
        graduation: graduation,
        photoUrl: photoUrlToSave, // Passa a URL (pode ser null, mas copyWith mantém se for null)
      );

      debugPrint('[EditProfileScreen] updatedProfile.photoUrl: ${updatedProfile.photoUrl}');
      debugPrint('[EditProfileScreen] ===========================');
      
      final result = await profileService.updateProfile(updatedProfile);

      if (mounted) {
        result.fold(
          onSuccess: (_) {
            // Recarrega o perfil para garantir que a foto está atualizada
            profileService.refresh();
            
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

  /// Constrói uma mini representação visual da faixa com ponteira preta (se aplicável)
  Widget _buildMiniBeltPreview(Belt belt) {
    const double width = 48;
    const double height = 16;

    if (belt.hasBlackTip) {
      // Faixa com ponteira (estilo BJJ)
      final tipColor = belt.tipColor ?? Colors.black;
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          border: belt.color == Colors.white
              ? Border.all(color: Colors.grey.shade400, width: 0.5)
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Row(
            children: [
              // Corpo da faixa
              Expanded(
                flex: 7,
                child: belt.secondaryColor != null
                    ? Row(
                        children: List.generate(6, (index) {
                          return Expanded(
                            child: Container(
                              color: index.isEven ? belt.color : belt.secondaryColor,
                            ),
                          );
                        }),
                      )
                    : Container(color: belt.color),
              ),
              // Ponteira (preta ou vermelha)
              Container(
                width: 14,
                color: tipColor,
              ),
            ],
          ),
        ),
      );
    }

    // Faixa sem ponteira preta
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: belt.secondaryColor == null ? belt.color : null,
        borderRadius: BorderRadius.circular(3),
        border: belt.color == Colors.white
            ? Border.all(color: Colors.grey.shade400)
            : null,
        gradient: belt.secondaryColor != null
            ? LinearGradient(
                colors: [belt.color, belt.secondaryColor!],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
      ),
    );
  }
}

