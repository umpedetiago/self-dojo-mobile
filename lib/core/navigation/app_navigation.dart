import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:self_dojo_mobile/core/config/app_router.dart';

/// Helper class para navegação type-safe
/// 
/// Use esta classe ao invés de usar strings diretamente em context.go() ou context.push()
/// 
/// Exemplo:
/// ```dart
/// // ❌ Incorreto
/// context.go('/academy/manage/$academyId');
/// 
/// // ✅ Correto
/// AppNavigation.goToManageAcademy(context, academyId: academyId);
/// ```
class AppNavigation {
  AppNavigation._();

  // ==================== Auth Routes ====================

  /// Navega para a tela de splash
  static void goToSplash(BuildContext context) {
    context.go(AppRoutes.splash);
  }

  /// Navega para a tela de login
  static void goToLogin(BuildContext context) {
    context.go(AppRoutes.login);
  }

  /// Navega para a tela de registro
  static void pushToRegister(BuildContext context) {
    context.push(AppRoutes.register);
  }

  // ==================== Home Routes ====================

  /// Navega para a tela home
  static void goToHome(BuildContext context) {
    context.go(AppRoutes.home);
  }

  // ==================== Profile Routes ====================

  /// Navega para a tela de editar perfil
  static void pushToEditProfile(BuildContext context) {
    context.push(AppRoutes.editProfile);
  }

  // ==================== Check-in Routes ====================

  /// Navega para a tela de check-in
  static void pushToCheckIn(BuildContext context) {
    context.push(AppRoutes.checkIn);
  }

  /// Navega para o histórico de check-in
  static void pushToCheckInHistory(BuildContext context) {
    context.push(AppRoutes.checkInHistory);
  }

  // ==================== Academy Routes ====================

  /// Navega para a tela de criar academia
  static void goToCreateAcademy(BuildContext context) {
    context.go(AppRoutes.createAcademy);
  }

  /// Navega para a tela de seleção de academias
  static void goToSelectAcademy(BuildContext context) {
    context.go(AppRoutes.selectAcademy);
  }

  /// Navega para a tela de gerenciamento de academia
  /// 
  /// Se [academyId] for fornecido, navega diretamente para essa academia.
  /// Caso contrário, navega para a tela de seleção.
  static void goToManageAcademy(
    BuildContext context, {
    String? academyId,
  }) {
    if (academyId != null && academyId.isNotEmpty) {
      context.go('/academy/manage/$academyId');
    } else {
      context.go(AppRoutes.manageAcademy);
    }
  }

  /// Navega para a tela de modalidades da academia
  static void pushToAcademyModalities(BuildContext context) {
    context.push(AppRoutes.academyModalities);
  }

  /// Navega para a tela de configuração de graduação
  static void pushToAcademyGraduation(
    BuildContext context, {
    required String type,
  }) {
    context.push('/academy/modalities/$type/graduation');
  }

  /// Navega para a tela de alunos da academia
  static void pushToAcademyStudents(BuildContext context) {
    context.push(AppRoutes.academyStudents);
  }

  /// Navega para os detalhes de um aluno
  static void pushToAcademyStudentDetail(
    BuildContext context, {
    required String memberId,
  }) {
    context.push('/academy/students/$memberId');
  }

  /// Navega para a tela de solicitações da academia
  static Future<T?> pushToAcademyRequests<T>(BuildContext context) {
    return context.push<T>(AppRoutes.academyRequests);
  }

  /// Navega para a tela de professores da academia
  static void pushToAcademyTeachers(BuildContext context) {
    context.push(AppRoutes.academyTeachers);
  }

  /// Navega para a tela de horários de aulas
  static void pushToAcademySchedules(BuildContext context) {
    context.push(AppRoutes.academySchedules);
  }

  /// Navega para a tela de editar academia
  static void pushToEditAcademy(
    BuildContext context, {
    required String academyId,
  }) {
    context.push('/academy/edit/$academyId');
  }

  /// Navega para a tela de assinatura da academia
  static void pushToAcademySubscription(BuildContext context) {
    context.push(AppRoutes.academySubscription);
  }

  /// Navega para a tela de buscar academia
  static void pushToSearchAcademy(BuildContext context) {
    context.push(AppRoutes.searchAcademy);
  }

  // ==================== Utility Methods ====================

  /// Volta para a tela anterior
  /// 
  /// Retorna o resultado se houver
  static void pop<T>(BuildContext context, [T? result]) {
    context.pop(result);
  }

  /// Verifica se é possível voltar
  static bool canPop(BuildContext context) {
    return context.canPop();
  }
}
