// lib/album_service.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AlbumService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 1) Стрім усіх альбомів (слухає оновлення в Firestore)
  Stream<QuerySnapshot<Map<String, dynamic>>> getAlbumsStream(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('albums')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// 2) Додає новий альбом у Firestore
  Future<void> addAlbum(String userId, String title) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('albums')
        .add({
          'title': title,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  /// 3) Оновлює назву альбому
  Future<void> updateAlbumTitle(
      String userId, String albumId, String newTitle) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('albums')
        .doc(albumId)
        .update({'title': newTitle});
  }

  /// 4) Видаляє альбом
  Future<void> deleteAlbum(String userId, String albumId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('albums')
        .doc(albumId)
        .delete();
  }

  /// 5) Оновлює порядок альбомів (якщо потрібно)
  Future<void> updateAlbumOrder(String userId, List<String> orderedIds) async {
    final batch = _db.batch();
    final col = _db
        .collection('users')
        .doc(userId)
        .collection('albums');
    for (var i = 0; i < orderedIds.length; i++) {
      batch.update(col.doc(orderedIds[i]), {'order': i});
    }
    return batch.commit();
  }

  /// 6) Зручний діалог для створення альбому
  Future<void> addAlbumDialog(BuildContext context, String userId) async {
    String title = '';
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Новий альбом'),
        content: TextField(
          decoration: const InputDecoration(labelText: 'Назва альбому'),
          onChanged: (v) => title = v,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Скасувати'),
          ),
          ElevatedButton(
            onPressed: () {
              if (title.trim().isNotEmpty) {
                addAlbum(userId, title.trim());
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Створити'),
          ),
        ],
      ),
    );
  }
}
