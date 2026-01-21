import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:self_dojo_mobile/core/utils/result.dart';
import 'package:flutter/foundation.dart';

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
    debugPrint('[SupabaseService] updateUser - ID: $id, Data: $data');
    try {
      final response = await _client
          .from('users')
          .update(data)
          .eq('id', id)
          .select();
      debugPrint('[SupabaseService] ✅ Usuário atualizado. Resposta: $response');
    } catch (e, stackTrace) {
      debugPrint('[SupabaseService] ❌ ERRO ao atualizar usuário: $e');
      debugPrint('[SupabaseService] StackTrace: $stackTrace');
      rethrow;
    }
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

  /// Lista academias do owner
  Future<List<Map<String, dynamic>>> getOwnerAcademies(String ownerId) async {
    // Primeiro busca o user_id pelo firebase_uid
    final user = await getUserByFirebaseUid(ownerId);
    if (user == null) return [];

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
        .order('created_at', ascending: true);

    return (response as List).cast<Map<String, dynamic>>();
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
      
      // Busca dados completos da modalidade da academia (incluindo belt_configs)
      String? martialArtType;
      Map<String, dynamic>? academyModalityData;
      final modalityId = modality['modality_id'] as String?;
      if (modalityId != null) {
        final academyModality = await _client
            .from('academy_modalities')
            .select('*, belt_configs(*)')
            .eq('id', modalityId)
            .maybeSingle();
        martialArtType = academyModality?['martial_art_type'] as String?;
        academyModalityData = academyModality;
      }
      
      results.add({
        ...modality,
        'graduation_history': historyResponse,
        'martial_art_type': martialArtType,
        'academy_modality': academyModalityData,
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
        .select('''
          *,
          class_schedules (
            id,
            start_time,
            end_time,
            day_of_week,
            academy_modalities (
              martial_art_type
            )
          )
        ''')
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
      debugPrint('[SupabaseService] Iniciando upload: bucket=$bucket, path=$path');
      
      // Verifica se o arquivo existe
      if (!await file.exists()) {
        debugPrint('[SupabaseService] ERRO: Arquivo não encontrado: ${file.path}');
        return Result.failure(
          Failure(message: 'Arquivo não encontrado: ${file.path}'),
        );
      }

      // Verifica o tamanho do arquivo (limite de 5MB)
      final fileSize = await file.length();
      debugPrint('[SupabaseService] Tamanho do arquivo: ${(fileSize / 1024).toStringAsFixed(2)} KB');
      const maxSize = 5 * 1024 * 1024; // 5MB
      if (fileSize > maxSize) {
        debugPrint('[SupabaseService] ERRO: Arquivo muito grande: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');
        return Result.failure(
          Failure(
            message: 'Arquivo muito grande. Tamanho máximo: 5MB',
          ),
        );
      }

      // Verifica se o bucket existe (opcional - pode falhar por permissões)
      // Se falhar, continua mesmo assim pois o upload vai falhar se o bucket não existir
      try {
        final buckets = await _client.storage.listBuckets();
        final bucketExists = buckets.any((b) => b.name == bucket);
        if (!bucketExists) {
          debugPrint('[SupabaseService] AVISO: Bucket "$bucket" não encontrado na lista, mas continuando...');
          // Não retorna erro aqui, deixa o upload tentar
          // Se o bucket realmente não existir, o upload vai falhar com erro mais específico
        } else {
          debugPrint('[SupabaseService] Bucket "$bucket" encontrado');
        }
      } catch (e) {
        debugPrint('[SupabaseService] AVISO: Não foi possível verificar bucket (pode ser problema de permissão): $e');
        debugPrint('[SupabaseService] Continuando com o upload mesmo assim...');
        // Continua mesmo assim, pode ser problema de permissão para listar buckets
        // O upload vai falhar se o bucket realmente não existir
      }

      // Faz upload com upsert para sobrescrever arquivos existentes
      debugPrint('[SupabaseService] Fazendo upload do arquivo...');
      try {
        // Tenta fazer upload (se arquivo já existe, vai dar erro)
        await _client.storage.from(bucket).upload(path, file);
        debugPrint('[SupabaseService] Upload realizado com sucesso');
      } on StorageException catch (e) {
        debugPrint('[SupabaseService] StorageException durante upload: statusCode=${e.statusCode}, message=${e.message}');
        
        // Se arquivo já existe (erro 409), tenta remover e fazer upload novamente
        if (e.statusCode == 409.toString() || e.message.contains('already exists')) {
          debugPrint('[SupabaseService] Arquivo já existe, tentando remover e re-upload...');
          try {
            await _client.storage.from(bucket).remove([path]);
            await _client.storage.from(bucket).upload(path, file);
            debugPrint('[SupabaseService] Re-upload realizado com sucesso após remoção');
          } catch (removeError) {
            debugPrint('[SupabaseService] ERRO ao remover arquivo existente: $removeError');
            rethrow;
          }
        } else {
          rethrow;
        }
      }

      // Obtém a URL pública do arquivo
      final url = _client.storage.from(bucket).getPublicUrl(path);
      debugPrint('[SupabaseService] URL pública gerada: $url');
      
      return Result.success(url);
    } on StorageException catch (e) {
      // Erro específico do Storage
      debugPrint('[SupabaseService] StorageException capturada: statusCode=${e.statusCode}, message=${e.message}');
      
      String errorMessage = 'Erro no upload';
      
      if (e.statusCode == 401.toString()) {
        errorMessage = 'Não autenticado. Faça login novamente.';
      } else if (e.statusCode == 403.toString()) {
        errorMessage = 'Sem permissão para fazer upload. Verifique as policies do Storage no Supabase.';
      } else if (e.statusCode == 404.toString()) {
        errorMessage = 'Bucket "$bucket" não encontrado. Crie o bucket no painel do Supabase.';
      } else if (e.statusCode == 413.toString()) {
        errorMessage = 'Arquivo muito grande. Tamanho máximo: 5MB';
      } else {
        errorMessage = 'Erro no upload (${e.statusCode}): ${e.message}';
      }
      
      return Result.failure(
        Failure(
          message: errorMessage,
          code: e.statusCode?.toString(),
        ),
      );
    } on HandshakeException catch (e) {
      // Erro de conexão SSL/TLS
      debugPrint('[SupabaseService] HandshakeException: $e');
      return Result.failure(
        Failure(
          message: 'Erro de conexão com o servidor. Verifique sua internet e tente novamente.',
          code: 'handshake_error',
        ),
      );
    } on SocketException catch (e) {
      // Erro de conexão de rede
      debugPrint('[SupabaseService] SocketException: $e');
      return Result.failure(
        Failure(
          message: 'Erro de conexão. Verifique sua internet e tente novamente.',
          code: 'network_error',
        ),
      );
    } on HttpException catch (e) {
      // Erro HTTP
      debugPrint('[SupabaseService] HttpException: $e');
      return Result.failure(
        Failure(
          message: 'Erro na comunicação com o servidor: ${e.message}',
          code: 'http_error',
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('[SupabaseService] Erro inesperado: $e');
      debugPrint('[SupabaseService] StackTrace: $stackTrace');
      
      // Mensagem mais amigável baseada no tipo de erro
      String errorMessage = 'Erro no upload';
      if (e.toString().contains('HandshakeException') || 
          e.toString().contains('handshake')) {
        errorMessage = 'Erro de conexão com o servidor. Verifique sua internet e tente novamente.';
      } else if (e.toString().contains('SocketException') ||
                 e.toString().contains('network')) {
        errorMessage = 'Erro de conexão. Verifique sua internet e tente novamente.';
      } else {
        errorMessage = 'Erro no upload: ${e.toString()}';
      }
      
      return Result.failure(
        Failure(message: errorMessage),
      );
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

  // ============================================
  // CLASS SCHEDULES (Horários de Aulas)
  // ============================================

  /// Cria horário de aula
  Future<Map<String, dynamic>> createClassSchedule(Map<String, dynamic> data) async {
    final response = await _client
        .from('class_schedules')
        .insert(data)
        .select()
        .single();
    return response;
  }

  /// Busca horários da academia
  Future<List<Map<String, dynamic>>> getClassSchedules(
    String academyId, {
    String? modalityId,
    int? dayOfWeek,
    bool? isActive,
  }) async {
    var query = _client
        .from('class_schedules')
        .select('''
          *,
          academy_modalities (
            id,
            martial_art_type
          ),
          users:instructor_id (
            id,
            display_name,
            photo_url
          )
        ''')
        .eq('academy_id', academyId);

    if (modalityId != null) {
      query = query.eq('modality_id', modalityId);
    }

    if (dayOfWeek != null) {
      query = query.eq('day_of_week', dayOfWeek);
    }

    if (isActive != null) {
      query = query.eq('is_active', isActive);
    }

    final response = await query.order('day_of_week').order('start_time');
    return List<Map<String, dynamic>>.from(response);
  }

  /// Busca horário por ID
  Future<Map<String, dynamic>?> getClassSchedule(String id) async {
    final response = await _client
        .from('class_schedules')
        .select('''
          *,
          academy_modalities (
            id,
            martial_art_type
          ),
          users:instructor_id (
            id,
            display_name,
            photo_url
          )
        ''')
        .eq('id', id)
        .maybeSingle();
    return response;
  }

  /// Atualiza horário de aula
  Future<void> updateClassSchedule(String id, Map<String, dynamic> data) async {
    await _client.from('class_schedules').update(data).eq('id', id);
  }

  /// Deleta horário de aula
  Future<void> deleteClassSchedule(String id) async {
    await _client.from('class_schedules').delete().eq('id', id);
  }

  /// Busca horários disponíveis para check-in (horários ativos do dia atual)
  Future<List<Map<String, dynamic>>> getAvailableSchedulesForCheckIn(
    String academyId,
  ) async {
    final now = DateTime.now();
    // DateTime.weekday retorna 1-7 (segunda=1, domingo=7)
    // Precisamos converter para 0-6 (domingo=0, sábado=6)
    final currentDayOfWeek = now.weekday == 7 ? 0 : now.weekday;
    
    final response = await _client
        .from('class_schedules')
        .select('''
          *,
          academy_modalities (
            id,
            martial_art_type
          ),
          users:instructor_id (
            id,
            display_name,
            photo_url
          )
        ''')
        .eq('academy_id', academyId)
        .eq('day_of_week', currentDayOfWeek)
        .eq('is_active', true)
        .order('start_time');
    
    return List<Map<String, dynamic>>.from(response);
  }
}

