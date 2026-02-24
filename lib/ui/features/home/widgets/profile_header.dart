import 'package:flutter/material.dart';
import 'package:self_dojo_mobile/core/theme/app_colors.dart';

/// Header do perfil na Home
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.displayName,
    required this.photoUrl,
    required this.martialArtName,
    required this.martialArtShortName,
    required this.martialArtPrimaryColor,
    required this.academyName,
    required this.onLogout,
    required this.onEditProfile,
  });

  
  final String? displayName;
  final String? photoUrl;
  final String? martialArtName;
  final String? martialArtShortName;
  final Color martialArtPrimaryColor;
  final String? academyName;
  final VoidCallback onLogout;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: onEditProfile,
            child: Stack(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: photoUrl == null
                        ? AppColors.primaryGradient
                        : null,
                    image: photoUrl != null && photoUrl!.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(photoUrl!),
                            fit: BoxFit.cover,
                            onError: (exception, stackTrace) {
                              // Se a imagem falhar ao carregar, mostra as iniciais
                              // O widget será reconstruído sem a imagem
                            },
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: photoUrl == null || photoUrl!.isEmpty
                      ? Center(
                          child: Text(
                            _getInitials(
                                displayName ?? ''),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : null,
                ),
                // Ícone de edição
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.backgroundDark,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Informações
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName ?? '',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.sports_martial_arts,
                      size: 16,
                      color: martialArtPrimaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      martialArtShortName ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondaryDark.withValues(alpha: 0.8),
                      ),
                    ),
                    if (academyName != null &&
                        academyName!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.circle,
                        size: 4,
                        color: AppColors.textTertiaryDark,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          academyName!,
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                AppColors.textSecondaryDark.withValues(alpha: 0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Botão de logout
          IconButton(
            onPressed: onLogout,
            icon: Icon(
              Icons.logout,
              color: AppColors.textSecondaryDark.withValues(alpha: 0.7),
            ),
            tooltip: 'Sair',
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';

    // Se for email, pega primeira letra antes do @
    if (name.contains('@')) {
      return name[0].toUpperCase();
    }

    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}

