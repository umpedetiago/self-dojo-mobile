import 'package:cloud_firestore/cloud_firestore.dart';

/// Service para acesso ao Firestore
class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Coleção de perfis de usuários
  CollectionReference<Map<String, dynamic>> get usersCollection =>
      _firestore.collection('users');

  /// Obtém documento de usuário por ID
  Future<DocumentSnapshot<Map<String, dynamic>>> getUser(String userId) {
    return usersCollection.doc(userId).get();
  }

  /// Cria ou atualiza perfil do usuário
  Future<void> setUser(String userId, Map<String, dynamic> data) {
    return usersCollection.doc(userId).set(data, SetOptions(merge: true));
  }

  /// Atualiza campos específicos do perfil
  Future<void> updateUser(String userId, Map<String, dynamic> data) {
    return usersCollection.doc(userId).update(data);
  }

  /// Stream de mudanças no perfil do usuário
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchUser(String userId) {
    return usersCollection.doc(userId).snapshots();
  }

  /// Incrementa contador de aulas
  Future<void> incrementClassCount(String userId) {
    return usersCollection.doc(userId).update({
      'totalClasses': FieldValue.increment(1),
      'graduation.classesAtCurrentBelt': FieldValue.increment(1),
    });
  }

  /// Adiciona registro ao histórico de graduações
  Future<void> addGraduationHistory(
    String userId,
    Map<String, dynamic> graduation,
  ) {
    return usersCollection.doc(userId).update({
      'graduationHistory': FieldValue.arrayUnion([graduation]),
    });
  }

  /// Adiciona competição ao perfil
  Future<void> addCompetition(
    String userId,
    Map<String, dynamic> competition,
  ) {
    return usersCollection.doc(userId).update({
      'competitions': FieldValue.arrayUnion([competition]),
    });
  }

  /// Deleta perfil do usuário
  Future<void> deleteUser(String userId) {
    return usersCollection.doc(userId).delete();
  }
}

