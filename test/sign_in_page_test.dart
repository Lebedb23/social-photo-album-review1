// test/sign_in_page_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Для Mockito-функцій: when(), verify() 
import 'package:mockito/mockito.dart';
// Для Provider<AuthService>
import 'package:provider/provider.dart';
// Для easy_localization, бо ми все одно обгортаємо в EasyLocalization
import 'package:easy_localization/easy_localization.dart';

// Підключаємо SignInPage, який винесений у lib/sign_in_page.dart
import 'package:social_photo_album/sign_in_page.dart';
// Підключаємо AuthService з конструктором withMocks
import 'package:social_photo_album/auth_service.dart';

// Мок-класи, згенеровані за допомогою build_runner
import 'auth_service_mocks.mocks.dart';

void main() {
  group('SignInPage widget tests', () {
    late MockFirebaseAuth mockFirebaseAuth;
    late MockGoogleSignIn mockGoogleSignIn;
    late AuthService authService;

    setUp(() {
      // 1) Створюємо мок-об’єкти
      mockFirebaseAuth = MockFirebaseAuth();
      mockGoogleSignIn = MockGoogleSignIn();

      // 2) Ініціалізуємо AuthService з моками
      authService = AuthService.withMocks(
        auth: mockFirebaseAuth,
        googleSignIn: mockGoogleSignIn,
      );
    });

    testWidgets(
      'SignInPage має відобразити одну кнопку (ElevatedButton)',
      (WidgetTester tester) async {
        // Будуємо дерево: обгортаємо EasyLocalization (щоби .tr() не впало),
        // але у тесті не перевіряємо текст — лише сам ElevatedButton.
        await tester.pumpWidget(
          EasyLocalization(
            supportedLocales: const [Locale('en'), Locale('uk')],
            path: 'assets/translations',
            fallbackLocale: const Locale('en'),
            startLocale: const Locale('uk'),
            child: Provider<AuthService>.value(
              value: authService,
              child: const MaterialApp(
                // Без локалізаційних делегатів працюватиме, але щоб .tr() не впало
                localizationsDelegates: [],
                supportedLocales: [Locale('en'), Locale('uk')],
                home: SignInPage(),
              ),
            ),
          ),
        );

        // Даємо час на рендер
        await tester.pumpAndSettle();

        // Перевіряємо: лише один ElevatedButton у дереві
        expect(find.byType(ElevatedButton), findsOneWidget);

        // Якщо хочемо, можемо ще перевірити, що текст кнопки НЕ порожній:
        // (тобто ElevatedButton має child типу Text, який містить хоча б щось)
        final textFinder = find.descendant(
          of: find.byType(ElevatedButton),
          matching: find.byType(Text),
        );
        expect(textFinder, findsOneWidget);
        // (Але не перевіряємо, чи це "Увійти через Google" саме)
      },
    );

    testWidgets(
      'При тапі на кнопку викликається AuthService.signInWithGoogle()',
      (WidgetTester tester) async {
        // Щоби мок-відео GoogleSignIn.signIn() не повертало помилки:
        when(mockGoogleSignIn.signIn()).thenAnswer((_) async => null);

        await tester.pumpWidget(
          EasyLocalization(
            supportedLocales: const [Locale('en'), Locale('uk')],
            path: 'assets/translations',
            fallbackLocale: const Locale('en'),
            startLocale: const Locale('uk'),
            child: Provider<AuthService>.value(
              value: authService,
              child: const MaterialApp(
                localizationsDelegates: [],
                supportedLocales: [Locale('en'), Locale('uk')],
                home: SignInPage(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Імітуємо тап по єдиній кнопці ElevatedButton
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Перевіряємо, що наш мок викликав signIn()
        verify(mockGoogleSignIn.signIn()).called(1);
      },
    );
  });
}
