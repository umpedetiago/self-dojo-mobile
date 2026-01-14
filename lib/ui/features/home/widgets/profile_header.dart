import 'package:flutter/material.dart';
import 'package:self_dojo_mobile/core/theme/app_colors.dart';
import 'package:self_dojo_mobile/domain/models/user_profile.dart';

/// Header do perfil na Home
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.profile,
    required this.onLogout,
    required this.onEditProfile,
  });

  final UserProfile profile;
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
                    gradient: profile.photoUrl == null
                        ? AppColors.primaryGradient
                        : null,
                    image: profile.photoUrl != null && profile.photoUrl!.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(profile.photoUrl!),
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
                  child: profile.photoUrl == null || profile.photoUrl!.isEmpty
                      ? Center(
                          child: Text(
                            _getInitials(
                                profile.displayName ?? profile.email),
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
                  profile.displayName ?? 'Usuário',
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
                      color: profile.martialArt.primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      profile.martialArt.shortName,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondaryDark.withValues(alpha: 0.8),
                      ),
                    ),
                    if (profile.academyName != null &&
                        profile.academyName!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.circle,
                        size: 4,
                        color: AppColors.textTertiaryDark,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          profile.academyName!,
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

