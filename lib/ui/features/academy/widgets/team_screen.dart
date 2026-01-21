import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:self_dojo_mobile/core/theme/app_colors.dart';
import 'package:self_dojo_mobile/data/repositories/academy_repository.dart';
import 'package:self_dojo_mobile/data/repositories/profile_repository.dart';
import 'package:self_dojo_mobile/data/services/supabase_service.dart';
import 'package:self_dojo_mobile/domain/models/academy/academy.dart';
import 'package:self_dojo_mobile/domain/models/academy/academy_modality.dart';
import 'package:self_dojo_mobile/ui/features/academy/view_models/academy_viewmodel.dart';
import 'package:self_dojo_mobile/ui/features/auth/view_models/auth_viewmodel.dart';

/// Tela para visualizar a equipe da academia (professores e instrutores)
class AcademyTeamScreen extends StatelessWidget {
  const AcademyTeamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final userId = auth.user.id;

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
      child: const _AcademyTeamContent(),
    );
  }
}

class _AcademyTeamContent extends StatefulWidget {
  const _AcademyTeamContent();

  @override
  State<_AcademyTeamContent> createState() => _AcademyTeamContentState();
}

class _AcademyTeamContentState extends State<_AcademyTeamContent> {
  Future<List<_TeamMember>>? _future;
  String? _academyId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final viewModel = context.watch<AcademyViewModel>();

    if (!viewModel.isLoading && viewModel.academy.id.isNotEmpty) {
      final id = viewModel.academy.id;
      if (_academyId != id) {
        _academyId = id;
        _future = _loadTeam(viewModel.academy);
      }
    }
  }

  Future<List<_TeamMember>> _loadTeam(Academy academy) async {
    final supabase = context.read<SupabaseService>();
    final Map<String, _TeamMember> byUser = {};

    for (final AcademyModality modality in academy.modalities) {
      final records = await supabase.getModalityTeachers(modality.id);

      for (final rec in records) {
        final userId = rec['user_id'] as String?;
        if (userId == null) continue;

        final role = (rec['role'] as String?)?.toLowerCase() ?? 'teacher';
        final userData = rec['users'] as Map<String, dynamic>? ?? {};
        final name =
            (userData['display_name'] as String?) ?? (userData['email'] as String?) ?? 'Sem nome';
        final email = userData['email'] as String? ?? '';
        final photoUrl = userData['photo_url'] as String?;

        final entry = byUser.putIfAbsent(
          userId,
          () => _TeamMember(
            id: userId,
            name: name,
            email: email,
            photoUrl: photoUrl,
            roles: <String>{},
            modalities: <String>{},
          ),
        );

        entry.roles.add(role);
        entry.modalities.add(modality.martialArt.shortName);
      }
    }

    final list = byUser.values.toList();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<AcademyViewModel>();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimaryDark),
        title: const Text(
          'Equipe',
          style: TextStyle(
            color: AppColors.textPrimaryDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: viewModel.isLoading || _future == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : FutureBuilder<List<_TeamMember>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Erro ao carregar equipe: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textSecondaryDark,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }

                final members = snapshot.data ?? [];
                if (members.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Ainda não há professores ou instrutores cadastrados.\n\n'
                        'Use o botão "Professores" nas modalidades para definir quem faz parte da equipe.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondaryDark,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }

                final teachers = members
                    .where((m) => m.roles.contains('teacher'))
                    .toList();
                final instructors = members
                    .where((m) => m.roles.contains('instructor'))
                    .toList();

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (teachers.isNotEmpty) ...[
                      const _SectionHeader(
                        icon: Icons.school,
                        title: 'Professores',
                      ),
                      const SizedBox(height: 8),
                      ...teachers.map(_TeamMemberCard.new),
                      const SizedBox(height: 24),
                    ],
                    if (instructors.isNotEmpty) ...[
                      const _SectionHeader(
                        icon: Icons.sports_martial_arts,
                        title: 'Instrutores',
                      ),
                      const SizedBox(height: 8),
                      ...instructors.map(_TeamMemberCard.new),
                      const SizedBox(height: 24),
                    ],
                    if (teachers.isEmpty && instructors.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Ainda não há professores ou instrutores cadastrados.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondaryDark,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimaryDark,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _TeamMember {
  _TeamMember({
    required this.id,
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.roles,
    required this.modalities,
  });

  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final Set<String> roles;
  final Set<String> modalities;
}

class _TeamMemberCard extends StatelessWidget {
  const _TeamMemberCard(this.member, {super.key});

  final _TeamMember member;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
            backgroundImage:
                member.photoUrl != null ? NetworkImage(member.photoUrl!) : null,
            child: member.photoUrl == null
                ? Text(
                    member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: const TextStyle(
                    color: AppColors.textPrimaryDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (member.email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    member.email,
                    style: const TextStyle(
                      color: AppColors.textSecondaryDark,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    ...member.roles.map(
                      (r) => Chip(
                        label: Text(
                          r == 'instructor'
                              ? 'Instrutor'
                              : 'Professor',
                          style: const TextStyle(fontSize: 11),
                        ),
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.15),
                        labelStyle: const TextStyle(
                          color: AppColors.textPrimaryDark,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        side: BorderSide.none,
                      ),
                    ),
                    ...member.modalities.map(
                      (m) => Chip(
                        label: Text(
                          m,
                          style: const TextStyle(fontSize: 11),
                        ),
                        backgroundColor:
                            AppColors.surfaceDark.withValues(alpha: 0.8),
                        labelStyle: const TextStyle(
                          color: AppColors.textSecondaryDark,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        side: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
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
}

