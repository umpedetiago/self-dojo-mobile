import 'package:cloud_firestore/cloud_firestore.dart';

/// Service para acesso às academias no Firestore
class AcademyService {
  AcademyService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Coleção de academias
  CollectionReference<Map<String, dynamic>> get academiesCollection =>
      _firestore.collection('academies');

  /// Obtém academia por ID
  Future<DocumentSnapshot<Map<String, dynamic>>> getAcademy(String academyId) {
    return academiesCollection.doc(academyId).get();
  }

  /// Cria ou atualiza academia
  Future<void> setAcademy(String academyId, Map<String, dynamic> data) {
    return academiesCollection.doc(academyId).set(data, SetOptions(merge: true));
  }

  /// Atualiza campos específicos da academia
  Future<void> updateAcademy(String academyId, Map<String, dynamic> data) {
    return academiesCollection.doc(academyId).update(data);
  }

  /// Stream de mudanças na academia
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchAcademy(String academyId) {
    return academiesCollection.doc(academyId).snapshots();
  }

  /// Busca academias por nome
  Future<QuerySnapshot<Map<String, dynamic>>> searchByName(String name) {
    return academiesCollection
        .where('name', isGreaterThanOrEqualTo: name)
        .where('name', isLessThanOrEqualTo: '$name\uf8ff')
        .where('isActive', isEqualTo: true)
        .limit(20)
        .get();
  }

  /// Busca academias por cidade
  Future<QuerySnapshot<Map<String, dynamic>>> searchByCity(String city) {
    return academiesCollection
        .where('city', isEqualTo: city)
        .where('isActive', isEqualTo: true)
        .limit(20)
        .get();
  }

  /// Busca academias por owner
  Future<QuerySnapshot<Map<String, dynamic>>> getByOwner(String ownerId) {
    return academiesCollection.where('ownerId', isEqualTo: ownerId).get();
  }

  /// Deleta academia (soft delete - marca como inativa)
  Future<void> deactivateAcademy(String academyId) {
    return academiesCollection.doc(academyId).update({
      'isActive': false,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // ============================================
  // SUBCOLEÇÕES
  // ============================================

  /// Coleção de alunos da academia
  CollectionReference<Map<String, dynamic>> studentsCollection(
          String academyId) =>
      academiesCollection.doc(academyId).collection('students');

  /// Coleção de solicitações de vinculação
  CollectionReference<Map<String, dynamic>> requestsCollection(
          String academyId) =>
      academiesCollection.doc(academyId).collection('requests');

  /// Coleção de pagamentos
  CollectionReference<Map<String, dynamic>> paymentsCollection(
          String academyId) =>
      academiesCollection.doc(academyId).collection('payments');

  /// Coleção de promoções
  CollectionReference<Map<String, dynamic>> promotionsCollection(
          String academyId) =>
      academiesCollection.doc(academyId).collection('promotions');

  // ============================================
  // ALUNOS
  // ============================================

  /// Adiciona aluno à academia
  Future<void> addStudent(
    String academyId,
    String studentId,
    Map<String, dynamic> data,
  ) {
    return studentsCollection(academyId).doc(studentId).set(data);
  }

  /// Atualiza dados do aluno
  Future<void> updateStudent(
    String academyId,
    String studentId,
    Map<String, dynamic> data,
  ) {
    return studentsCollection(academyId).doc(studentId).update(data);
  }

  /// Remove aluno da academia
  Future<void> removeStudent(String academyId, String studentId) {
    return studentsCollection(academyId).doc(studentId).delete();
  }

  /// Obtém lista de alunos
  Future<QuerySnapshot<Map<String, dynamic>>> getStudents(String academyId) {
    return studentsCollection(academyId).get();
  }

  /// Stream de alunos
  Stream<QuerySnapshot<Map<String, dynamic>>> watchStudents(String academyId) {
    return studentsCollection(academyId).snapshots();
  }

  /// Conta total de alunos
  Future<int> countStudents(String academyId) async {
    final snapshot = await studentsCollection(academyId).count().get();
    return snapshot.count ?? 0;
  }

  // ============================================
  // SOLICITAÇÕES
  // ============================================

  /// Cria solicitação de vinculação
  Future<DocumentReference<Map<String, dynamic>>> createRequest(
    String academyId,
    Map<String, dynamic> data,
  ) {
    return requestsCollection(academyId).add(data);
  }

  /// Atualiza solicitação
  Future<void> updateRequest(
    String academyId,
    String requestId,
    Map<String, dynamic> data,
  ) {
    return requestsCollection(academyId).doc(requestId).update(data);
  }

  /// Obtém solicitações pendentes
  Future<QuerySnapshot<Map<String, dynamic>>> getPendingRequests(
      String academyId) {
    return requestsCollection(academyId)
        .where('status', isEqualTo: 'pending')
        .orderBy('requestedAt', descending: true)
        .get();
  }

  /// Stream de solicitações pendentes
  Stream<QuerySnapshot<Map<String, dynamic>>> watchPendingRequests(
      String academyId) {
    return requestsCollection(academyId)
        .where('status', isEqualTo: 'pending')
        .orderBy('requestedAt', descending: true)
        .snapshots();
  }

  // ============================================
  // PROMOÇÕES
  // ============================================

  /// Registra promoção
  Future<DocumentReference<Map<String, dynamic>>> addPromotion(
    String academyId,
    Map<String, dynamic> data,
  ) {
    return promotionsCollection(academyId).add(data);
  }

  /// Obtém histórico de promoções de um aluno
  Future<QuerySnapshot<Map<String, dynamic>>> getStudentPromotions(
    String academyId,
    String studentId,
  ) {
    return promotionsCollection(academyId)
        .where('userId', isEqualTo: studentId)
        .orderBy('promotedAt', descending: true)
        .get();
  }
}

