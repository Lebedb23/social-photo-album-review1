// test/album_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

import 'package:social_photo_album/album_service.dart';

void main() {
  group('AlbumService unit tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late AlbumService albumService;

    setUp(() {
      // 1) Створюємо “мокований” Firestore (FakeFirebaseFirestore)
      fakeFirestore = FakeFirebaseFirestore();

      // 2) Передаємо наш fakeFirestore у AlbumService
      albumService = AlbumService(firestore: fakeFirestore);
    });

    test('addAlbum() створює документ із правильними полями', () async {
      const userId = 'test_user';
      const albumTitle = 'My Test Album';

      // Викликаємо addAlbum – додається документ до fakeFirestore
      await albumService.addAlbum(userId, albumTitle);

      // Дістаємо усі документи у колекції albums для цього userId
      final snapshot = await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('albums')
          .get();

      // Маємо точно один документ
      expect(snapshot.docs.length, 1);

      // Беремо дані першого (і єдиного) документа
      final data = snapshot.docs.first.data();

      // Поле 'title' має збігатися з albumTitle
      expect(data['title'], albumTitle);

      // Поле 'createdAt' має існувати і бути типу Timestamp
      expect(data.containsKey('createdAt'), true);
      expect(data['createdAt'], isA<Timestamp>());
    });

    test('getAlbumsStream() повертає порожній стрім спочатку', () async {
      const userId = 'another_user';

      // Отримуємо стрім
      final stream = albumService.getAlbumsStream(userId);

      // Беремо перший івент зі стріму
      final firstSnapshot = await stream.first;

      // Очікуємо, що колекція ще порожня (жодного документа)
      expect(firstSnapshot.docs, isEmpty);
    });
  });
}
