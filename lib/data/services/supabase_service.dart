import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:self_dojo_mobile/core/utils/result.dart';

/// Serviço para interação com o Supabase
class SupabaseService {
  SupabaseService() : _client = Supabase.instance.client;

  final SupabaseClient _client;

  // ============================================
  // USERS
  // ============================================

  /// Busca usuário pelo Firebase UID
  Future<Map<String, dynamic>?> getUserByFirebaseUid(String firebaseUid) async {
    final response = await _client
        .from('users')
        .select()
        .eq('firebase_uid', firebaseUid)
        .maybeSingle();
    return response;
  }

  /// Cria ou atualiza usuário
  Future<Map<String, dynamic>> upsertUser(Map<String, dynamic> data) async {
    final response = await _client
        .from('users')
        .upsert(data, onConflict: 'firebase_uid')
        .select()
        .single();
    return response;
  }

  /// Atualiza usuário
  Future<void> updateUser(String id, Map<String, dynamic> data) async {
    await _client.from('users').update(data).eq('id', id);
  }

  // ============================================
  // ACADEMIES
  // ============================================

  /// Busca academia por ID
  Future<Map<String, dynamic>?> getAcademy(String id) async {
    final response = await _client
        .from('academies')
        .select('''
          *,
          academy_modalities (
            *,
            belt_configs (*)
          )
        ''')
        .eq('id', id)
        .maybeSingle();
    return response;
  }

  /// Busca academia do owner
  Future<Map<String, dynamic>?> getOwnerAcademy(String ownerId) async {
    // Primeiro busca o user_id pelo firebase_uid
    final user = await getUserByFirebaseUid(ownerId);
    if (user == null) return null;

    final response = await _client
        .from('academies')
        .select('''
          *,
          academy_modalities (
            *,
            belt_configs (*)
          )
        ''')
        .eq('owner_id', user['id'])
        .maybeSingle();
    return response;
  }

  /// Cria academia
  Future<Map<String, dynamic>> createAcademy(Map<String, dynamic> data) async {
    final response = await _client
        .from('academies')
        .insert(data)
        .select('''
          *,
          academy_modalities (
            *,
            belt_configs (*)
          )
        ''')
        .single();
    return response;
  }

  /// Atualiza academia
  Future<void> updateAcademy(String id, Map<String, dynamic> data) async {
    await _client.from('academies').update(data).eq('id', id);
  }

  /// Stream de academia
  /// Nota: Supabase stream não suporta joins, então buscamos completo após mudança
  Stream<Map<String, dynamic>?> watchAcademy(String id) {
    return _client
        .from('academies')
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .asyncMap((list) async {
          if (list.isEmpty) return null;
          // Busca academia completa com modalidades
          return await getAcademy(id);
        });
  }

  /// Busca academias por nome ou cidade
  Future<List<Map<String, dynamic>>> searchAcademies({
    String? query,
    String? city,
    String? modalityType,
    int limit = 20,
  }) async {
    var request = _client.from('academies').select('''
      *,
      academy_modalities (
        martial_art_type
      )
    ''');

    // Aplica filtro de busca se houver query
    if (query != null && query.isNotEmpty) {
      request = request.or('name.ilike.%$query%,city.ilike.%$query%');
    }

    if (city != null && city.isNotEmpty) {
      request = request.ilike('city', '%$city%');
    }

    final response = await request.limit(limit).order('name');
    
    // Filtra resultados em memória
    var results = List<Map<String, dynamic>>.from(response);
    
    // Filtra academias inativas (is_active = false explicitamente)
    results = results.where((academy) {
      final isActive = academy['is_active'];
      return isActive == null || isActive == true;
    }).toList();
    
    // Filtra por modalidade se especificado
    if (modalityType != null) {
      results = results.where((academy) {
        final modalities = academy['academy_modalities'] as List? ?? [];
        return modalities.any((m) => m['martial_art_type'] == modalityType);
      }).toList();
    }

    return results;
  }

  /// Verifica se usuário já tem solicitação pendente para academia
  Future<Map<String, dynamic>?> getPendingRequest(
      String academyId, String oderId) async {
    final response = await _client
        .from('academy_members')
        .select()
        .eq('academy_id', academyId)
        .eq('user_id', oderId)
        .maybeSingle();
    return response;
  }

  /// Cria solicitação de vínculo
  Future<Map<String, dynamic>> createMemberRequest(
      Map<String, dynamic> data) async {
    final response = await _client
        .from('academy_members')
        .insert(data)
        .select()
        .single();
    return response;
  }

  /// Cancela solicitação de vínculo
  Future<void> cancelMemberRequest(String memberId) async {
    await _client.from('academy_members').delete().eq('id', memberId);
  }

  /// Conta solicitações pendentes da academia
  Future<int> countPendingRequests(String academyId) async {
    final response = await _client
        .from('academy_members')
        .select('id')
        .eq('academy_id', academyId)
        .eq('status', 'pending');
    return (response as List).length;
  }

  /// Busca solicitações pendentes da academia
  Future<List<Map<String, dynamic>>> getPendingRequests(
      String academyId) async {
    // Busca membros pendentes
    final members = await _client
        .from('academy_members')
        .select()
        .eq('academy_id', academyId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    
    final results = <Map<String, dynamic>>[];
    
    // Para cada membro, busca os dados do usuário
    for (final member in members) {
      final userId = member['user_id'] as String?;
      if (userId != null) {
        final user = await _client
            .from('users')
            .select()
            .eq('id', userId)
            .maybeSingle();
        
        results.add({
          ...member,
          'users': user,
        });
      } else {
        results.add(member);
      }
    }
    
    return results;
  }

  /// Aprova solicitação
  Future<void> approveMemberRequest(String memberId) async {
    await _client.from('academy_members').update({
      'status': 'approved',
      'joined_at': DateTime.now().toIso8601String(),
    }).eq('id', memberId);
  }

  /// Rejeita solicitação
  Future<void> rejectMemberRequest(String memberId) async {
    await _client.from('academy_members').delete().eq('id', memberId);
  }

  // ============================================
  // ACADEMY MODALITIES
  // ============================================

  /// Adiciona modalidade à academia
  Future<Map<String, dynamic>> addModality(Map<String, dynamic> data) async {
    final response = await _client
        .from('academy_modalities')
        .insert(data)
        .select()
        .single();
    return response;
  }

  /// Atualiza modalidade
  Future<void> updateModality(String id, Map<String, dynamic> data) async {
    await _client.from('academy_modalities').update(data).eq('id', id);
  }

  /// Remove modalidade
  Future<void> deleteModality(String id) async {
    await _client.from('academy_modalities').delete().eq('id', id);
  }

  /// Busca modalidades da academia
  Future<List<Map<String, dynamic>>> getAcademyModalities(
      String academyId) async {
    final response = await _client
        .from('academy_modalities')
        .select('*, belt_configs(*)')
        .eq('academy_id', academyId);
    return List<Map<String, dynamic>>.from(response);
  }

  // ============================================
  // BELT CONFIGS
  // ============================================

  /// Upsert configurações de faixa
  Future<void> upsertBeltConfigs(
      String modalityId, List<Map<String, dynamic>> configs) async {
    // Remove configs existentes
    await _client.from('belt_configs').delete().eq('modality_id', modalityId);

    // Insere novas configs
    if (configs.isNotEmpty) {
      final data = configs.map((c) {
        return {...c, 'modality_id': modalityId};
      }).toList();
      await _client.from('belt_configs').insert(data);
    }
  }

  // ============================================
  // ACADEMY MEMBERS
  // ============================================

  /// Busca membro da academia
  Future<Map<String, dynamic>?> getAcademyMember(
      String academyId, String userId) async {
    final member = await _client
        .from('academy_members')
        .select()
        .eq('academy_id', academyId)
        .eq('user_id', userId)
        .maybeSingle();
    
    if (member == null) return null;
    
    // Busca dados do usuário
    final user = await _client
        .from('users')
        .select()
        .eq('id', userId)
        .maybeSingle();
    
    return {
      ...member,
      'users': user,
    };
  }

  /// Busca membros da academia
  Future<List<Map<String, dynamic>>> getAcademyMembers(String academyId,
      {String? status, String? role}) async {
    var query = _client
        .from('academy_members')
        .select()
        .eq('academy_id', academyId);

    if (status != null) {
      query = query.eq('status', status);
    }
    if (role != null) {
      query = query.eq('role', role);
    }

    final members = await query;
    final results = <Map<String, dynamic>>[];

    // Para cada membro, busca os dados do usuário
    for (final member in members) {
      final userId = member['user_id'] as String?;
      if (userId != null) {
        final user = await _client
            .from('users')
            .select()
            .eq('id', userId)
            .maybeSingle();
        
        results.add({
          ...member,
          'users': user,
        });
      }
    }

    return results;
  }

  /// Conta membros da academia
  Future<int> countAcademyMembers(String academyId, {String? status}) async {
    var query = _client
        .from('academy_members')
        .select('id')
        .eq('academy_id', academyId);

    if (status != null) {
      query = query.eq('status', status);
    }

    final response = await query;
    return response.length;
  }

  /// Cria membro
  Future<Map<String, dynamic>> createMember(Map<String, dynamic> data) async {
    final response =
        await _client.from('academy_members').insert(data).select().single();
    return response;
  }

  /// Atualiza membro
  Future<void> updateMember(String id, Map<String, dynamic> data) async {
    await _client.from('academy_members').update(data).eq('id', id);
  }

  /// Busca o membro da academia pelo user_id (para qualquer academia)
  Future<Map<String, dynamic>?> getMemberByUserId(String userId) async {
    final member = await _client
        .from('academy_members')
        .select()
        .eq('user_id', userId)
        .eq('status', 'approved')
        .maybeSingle();
    return member;
  }

  /// Busca todas as modalidades matriculadas de um usuário pelo user_id
  Future<List<Map<String, dynamic>>> getUserEnrolledModalities(
      String userId) async {
    // Primeiro busca o membro aprovado
    final member = await getMemberByUserId(userId);
    if (member == null) return [];

    // Busca as modalidades do membro
    return getStudentModalities(member['id'] as String);
  }

  // ============================================
  // STUDENT MODALITIES
  // ============================================

  /// Busca modalidades do aluno
  Future<List<Map<String, dynamic>>> getStudentModalities(
      String memberId) async {
    // Busca modalidades do aluno
    final modalities = await _client
        .from('student_modalities')
        .select()
        .eq('member_id', memberId);
    
    final results = <Map<String, dynamic>>[];
    
    for (final modality in modalities) {
      // Busca histórico de graduação
      final historyResponse = await _client
          .from('graduation_history')
          .select()
          .eq('student_modality_id', modality['id'])
          .order('promoted_at', ascending: false);
      
      // Busca o tipo da modalidade da tabela academy_modalities
      String? martialArtType;
      final modalityId = modality['modality_id'] as String?;
      if (modalityId != null) {
        final academyModality = await _client
            .from('academy_modalities')
            .select('martial_art_type')
            .eq('id', modalityId)
            .maybeSingle();
        martialArtType = academyModality?['martial_art_type'] as String?;
      }
      
      results.add({
        ...modality,
        'graduation_history': historyResponse,
        'martial_art_type': martialArtType,
      });
    }
    
    return results;
  }

  /// Matricula aluno em modalidade
  Future<Map<String, dynamic>> enrollInModality(
      Map<String, dynamic> data) async {
    final response = await _client
        .from('student_modalities')
        .insert(data)
        .select()
        .single();
    return response;
  }

  /// Atualiza modalidade do aluno
  Future<void> updateStudentModality(
      String id, Map<String, dynamic> data) async {
    await _client.from('student_modalities').update(data).eq('id', id);
  }

  /// Remove matrícula de modalidade
  Future<void> deleteStudentModality(String id) async {
    await _client.from('student_modalities').delete().eq('id', id);
  }

  /// Incrementa aulas do aluno (usa function do Postgres)
  Future<void> incrementStudentClasses(String studentModalityId) async {
    await _client.rpc('increment_student_classes',
        params: {'p_student_modality_id': studentModalityId});
  }

  /// Promove aluno (usa function do Postgres)
  Future<void> promoteStudent({
    required String studentModalityId,
    required String newBeltId,
    int degree = 0,
    String? promotedBy,
    String? notes,
  }) async {
    await _client.rpc('promote_student', params: {
      'p_student_modality_id': studentModalityId,
      'p_new_belt_id': newBeltId,
      'p_degree': degree,
      'p_promoted_by': promotedBy,
      'p_notes': notes,
    });
  }

  // ============================================
  // CHECK-INS
  // ============================================

  /// Registra check-in
  Future<Map<String, dynamic>> createCheckIn(Map<String, dynamic> data) async {
    final response =
        await _client.from('check_ins').insert(data).select().single();

    // Incrementa contador de aulas
    if (data['student_modality_id'] != null) {
      await incrementStudentClasses(data['student_modality_id']);
    }

    return response;
  }

  /// Busca check-ins do aluno
  Future<List<Map<String, dynamic>>> getStudentCheckIns(
    String studentModalityId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _client
        .from('check_ins')
        .select()
        .eq('student_modality_id', studentModalityId)
        .order('checked_in_at', ascending: false);

    // Note: date filtering should be done with proper date functions
    final response = await query;
    return List<Map<String, dynamic>>.from(response);
  }

  // ============================================
  // STORAGE
  // ============================================

  /// Upload de arquivo
  Future<Result<String>> uploadFile({
    required String bucket,
    required String path,
    required File file,
  }) async {
    try {
      await _client.storage.from(bucket).upload(path, file);
      final url = _client.storage.from(bucket).getPublicUrl(path);
      return Result.success(url);
    } catch (e) {
      return Result.failure(Failure(message: 'Erro no upload: $e'));
    }
  }

  /// Upload de bytes
  Future<Result<String>> uploadBytes({
    required String bucket,
    required String path,
    required Uint8List bytes,
  }) async {
    try {
      await _client.storage.from(bucket).uploadBinary(path, bytes);
      final url = _client.storage.from(bucket).getPublicUrl(path);
      return Result.success(url);
    } catch (e) {
      return Result.failure(Failure(message: 'Erro no upload: $e'));
    }
  }

  /// Deleta arquivo
  Future<void> deleteFile(String bucket, String path) async {
    await _client.storage.from(bucket).remove([path]);
  }
}

