import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

/// Service para upload de arquivos no Firebase Storage
class StorageService {
  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  /// Referência para a pasta de fotos de perfil
  Reference get profilePhotosRef => _storage.ref().child('profile_photos');

  /// Faz upload da foto de perfil e retorna a URL
  Future<String> uploadProfilePhoto({
    required String userId,
    required File file,
  }) async {
    // Cria referência com nome único baseado no userId
    final ref = profilePhotosRef.child('$userId.jpg');

    // Faz upload do arquivo
    final uploadTask = ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    // Aguarda conclusão do upload
    final snapshot = await uploadTask;

    // Retorna a URL de download
    return snapshot.ref.getDownloadURL();
  }

  /// Deleta foto de perfil
  Future<void> deleteProfilePhoto(String userId) async {
    try {
      final ref = profilePhotosRef.child('$userId.jpg');
      await ref.delete();
    } catch (e) {
      // Ignora erro se arquivo não existir
    }
  }

  /// Obtém URL da foto de perfil
  Future<String?> getProfilePhotoUrl(String userId) async {
    try {
      final ref = profilePhotosRef.child('$userId.jpg');
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }
}

