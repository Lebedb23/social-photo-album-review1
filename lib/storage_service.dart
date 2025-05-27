import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadImage(Uint8List data, String userId) async {
    final ref = _storage
        .ref()
        .child('user_images')
        .child('$userId-${DateTime.now().millisecondsSinceEpoch}.jpg');
    await ref.putData(data);
    return ref.getDownloadURL();
  }
}
