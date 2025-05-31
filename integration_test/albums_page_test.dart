// integration_test/albums_page_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// Щоб ініціалізувати Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Ваші опції згенеровані FlutterFire (зазвичай лежать у lib/firebase_options.dart)
import 'package:social_photo_album/firebase_options.dart';

// Сам екран AlbumsPage
import 'package:social_photo_album/albums_page.dart';

void main() {
  // Вказуємо Flutter Test Binding, що це integration test
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Integration Test: AlbumsPage має кнопку додати', (tester) async {
    // ────────────────────────────────────────────────────────────────────────────
    // 1) Ініціалізуємо Firebase у тесті (щоб був доступ до Firestore & Auth)
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 2) Авторизуємося анонімно, щоб у FirebaseAuth.instance.currentUser.uid був непустий рядок
    await FirebaseAuth.instance.signInAnonymously();
    // ────────────────────────────────────────────────────────────────────────────

    // 3) Тепер «надуваємо» на екран сам AlbumsPage
    await tester.pumpWidget(
      const MaterialApp(
        home: AlbumsPage(),
      ),
    );

    // 4) Чекаємо, доки Flutter домалює все (StreamBuilder, анімації, й т.д.)
    await tester.pumpAndSettle();

    // 5) Переконуємося, що на екрані є кнопка “додати” (Icons.add) саме в AlbumsPage
    final addIconFinder = find.byIcon(Icons.add);
    expect(addIconFinder, findsOneWidget);

    // Якщо ви хочете також перевірити заголовок,
    // і в AlbumsPage у вас він written як literal Text('Мої альбоми'),
    // тоді можна розкоментувати два рядки нижче:
    //
    // final titleFinder = find.text('Мої альбоми');
    // expect(titleFinder, findsOneWidget);
  });
}
