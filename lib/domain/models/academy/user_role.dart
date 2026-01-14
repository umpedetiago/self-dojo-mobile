/// Roles (papéis) de usuários no sistema
enum UserRole {
  /// Aluno - praticante comum
  student,

  /// Instrutor - auxilia nas aulas, faz check-in
  instructor,

  /// Professor - ensina e pode promover alunos
  teacher,

  /// Mestre de Modalidade - gerencia uma arte marcial específica
  /// Indicado pelo Owner, sem obrigações financeiras
  modalityMaster,

  /// Owner (Mestre Principal) - dono/contratante da academia
  /// Responsável financeiro pelo app
  owner,
}

/// Extensão com helpers para UserRole
extension UserRoleExtension on UserRole {
  /// Nome de exibição do role
  String get displayName {
    switch (this) {
      case UserRole.student:
        return 'Aluno';
      case UserRole.instructor:
        return 'Instrutor';
      case UserRole.teacher:
        return 'Professor';
      case UserRole.modalityMaster:
        return 'Mestre de Modalidade';
      case UserRole.owner:
        return 'Mestre (Dono de Academia)';
    }
  }

  /// Descrição do role
  String get description {
    switch (this) {
      case UserRole.student:
        return 'Praticante de artes marciais';
      case UserRole.instructor:
        return 'Auxilia nas aulas e faz check-in';
      case UserRole.teacher:
        return 'Ensina e promove alunos';
      case UserRole.modalityMaster:
        return 'Responsável por uma modalidade específica';
      case UserRole.owner:
        return 'Dono e responsável financeiro pela academia';
    }
  }

  /// Nível hierárquico (maior = mais permissões)
  int get level {
    switch (this) {
      case UserRole.student:
        return 0;
      case UserRole.instructor:
        return 1;
      case UserRole.teacher:
        return 2;
      case UserRole.modalityMaster:
        return 3;
      case UserRole.owner:
        return 4;
    }
  }

  /// Verifica se tem permissão igual ou superior a outro role
  bool hasPermissionOf(UserRole other) => level >= other.level;

  /// Verifica se pode gerenciar outro role
  bool canManage(UserRole other) => level > other.level;

  /// Verifica se pode promover alunos
  bool get canPromote =>
      this == UserRole.teacher ||
      this == UserRole.modalityMaster ||
      this == UserRole.owner;

  /// Verifica se pode configurar graduações
  bool get canConfigureGraduation =>
      this == UserRole.modalityMaster || this == UserRole.owner;

  /// Verifica se pode gerenciar financeiro
  bool get canManageFinancial => this == UserRole.owner;

  /// Verifica se pode ver lista de alunos
  bool get canViewStudents => level >= UserRole.instructor.level;
}

/// Status do usuário na academia
enum AcademyStatus {
  /// Aguardando aprovação
  pending,

  /// Aprovado/Ativo
  approved,

  /// Bloqueado (inadimplente, etc)
  blocked,

  /// Rejeitado
  rejected,
}

/// Extensão para AcademyStatus
extension AcademyStatusExtension on AcademyStatus {
  String get displayName {
    switch (this) {
      case AcademyStatus.pending:
        return 'Pendente';
      case AcademyStatus.approved:
        return 'Aprovado';
      case AcademyStatus.blocked:
        return 'Bloqueado';
      case AcademyStatus.rejected:
        return 'Rejeitado';
    }
  }

  bool get isActive => this == AcademyStatus.approved;
}

/// Status de pagamento do aluno
enum PaymentStatus {
  /// Em dia
  active,

  /// Pagamento pendente
  pending,

  /// Atrasado
  overdue,

  /// Isento (bolsista, etc)
  exempt,
}

/// Extensão para PaymentStatus
extension PaymentStatusExtension on PaymentStatus {
  String get displayName {
    switch (this) {
      case PaymentStatus.active:
        return 'Em dia';
      case PaymentStatus.pending:
        return 'Pendente';
      case PaymentStatus.overdue:
        return 'Atrasado';
      case PaymentStatus.exempt:
        return 'Isento';
    }
  }

  bool get canCheckIn =>
      this == PaymentStatus.active || this == PaymentStatus.exempt;
}

