import 'package:self_dojo_mobile/core/utils/result.dart';
import 'package:self_dojo_mobile/domain/models/academy/academy.dart';
import 'package:self_dojo_mobile/domain/models/academy/academy_modality.dart';
import 'package:self_dojo_mobile/domain/models/martial_arts/martial_art.dart';

/// Repository de academias
abstract class AcademyRepository {
  /// Obtém academia por ID
  Future<Result<Academy?>> getAcademy(String academyId);

  /// Stream de mudanças na academia
  Stream<Academy?> watchAcademy(String academyId);

  /// Cria nova academia (com trial)
  Future<Result<Academy>> createAcademy({
    required String ownerId,
    required String name,
    required List<MartialArtType> modalities,
    String? description,
    String? address,
    String? city,
    String? state,
    String? phone,
    String? email,
  });

  /// Atualiza academia
  Future<Result<void>> updateAcademy(Academy academy);

  /// Obtém academia do owner
  Future<Result<Academy?>> getOwnerAcademy(String ownerId);

  /// Adiciona modalidade
  Future<Result<void>> addModality(
    String academyId,
    MartialArtType type,
  );

  /// Remove modalidade
  Future<Result<void>> removeModality(
    String academyId,
    MartialArtType type,
  );

  /// Define mestre de modalidade
  Future<Result<void>> setModalityMaster(
    String academyId,
    MartialArtType type,
    String? masterId,
  );

  /// Atualiza configuração de graduação
  Future<Result<void>> updateGraduationConfig(
    String academyId,
    MartialArtType type,
    GraduationConfig config,
  );

  /// Conta alunos
  Future<Result<int>> countStudents(String academyId);

  /// Conta solicitações pendentes
  Future<Result<int>> countPendingRequests(String academyId);
}
