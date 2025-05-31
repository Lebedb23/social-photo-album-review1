// lib/storage_service.dart

import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Повертає об'єкт Reference для заданого шляху у Storage
  Reference storageRef(String path) {
    return _storage.ref(path);
  }

  /// Завантажує "bytes" у Storage під шляхом users/{uid}/photos/{timestamp}.jpg
  /// Повертає URL на завантажений файл
  Future<String> uploadImage(Uint8List bytes, String userId) async {
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final path = 'users/$userId/photos/$fileName.jpg';
    final ref = _storage.ref(path);
    final uploadTask = ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    await uploadTask;
    return await ref.getDownloadURL();
  }
}
