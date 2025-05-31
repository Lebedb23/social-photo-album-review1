// integration_test/app_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// Підключаємо клас SignInPage безпосередньо (щоб не запускати весь AuthWrapper)
import 'package:social_photo_album/sign_in_page.dart';
// І HomePage або AlbumsPage, щоб перевірити їхню появу
import 'package:social_photo_album/albums_page.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Інтеграція: SignInPage → AlbumsPage', (WidgetTester tester) async {
    // 1) ОДРАЗУ показуємо SignInPage у MaterialApp.
    //    Тобто не викликаємо app.main(), а пишемо мінімально необхідний “хост”
    await tester.pumpWidget(
      MaterialApp(
        // Щоб .tr() не викликав помилку, обгортаємо локалізацією:
        localizationsDelegates: const [
          // Якщо у вас використовуються локалізовані рядки у самих віджетах SignInPage,
          // сюди можна додати делегати з flutter_localizations, але якщо SignInPage
          // відображає текст “Увійти через Google” саме як літерал, можна їх пропустити.
        ],
        home: const SignInPage(),
      ),
    );

    // Даємо час на побудову першого екрану
    await tester.pumpAndSettle();

    // 2) Знаходимо кнопку входу (ElevatedButton). Ми вже у SignInPage, тому вона є.
    final signInButton = find.byType(ElevatedButton);
    expect(signInButton, findsOneWidget);

    // 3) Тапаємо на кнопку: SignInPage має після цього перейти на AlbumsPage.
    await tester.tap(signInButton);
    await tester.pumpAndSettle();

    // 4) Перевіряємо, що на екрані тепер є заголовок зі списком альбомів.
    //    Вважаємо, що AlbumsPage містить текст “Мої альбоми” (українською),
    //    або “My Albums” (англійською), залежно від вашої UI-реалізації.
    //    Наприклад, якщо у AlbumsPage ви показуєте:
    //      Text('Мої альбоми', style: TextStyle(...))
    //    тоді шукаємо саме цей рядок:
    final albumsTitle = find.text('Мої альбоми');
    expect(albumsTitle, findsOneWidget);

    // 5) Додатково перевіряємо, що є кнопка “додати” (Icon(Icons.add)) десь на екрані:
    final addIcon = find.byIcon(Icons.add);
    expect(addIcon, findsOneWidget);
  });
}
