# Social Photo Album

**Social Photo Album** — це Flutter-додаток для збереження та обміну фотографіями.  
Він використовує Firebase (Auth, Firestore, Storage) для бекенду, підтримує мультимовність (easy_localization), темну/світлу тему (ThemeNotifier + Provider), локальне кешування (Hive) та має набір unit/widget/integration тестів.

---

## 📖 Зміст

1. [Огляд](#огляд)  
2. [Передумови](#передумови)  
3. [Швидкий старт](#швидкий-старт)  
   - [1) Клонування репозиторію](#1-клонування-репозиторію)  
   - [2) Файл `.env`](#2-файл-env)  
   - [3) Розміщення Firebase-файлів](#3-розміщення-firebase-файлів)  
   - [4) Інсталяція залежностей](#4-інсталяція-залежностей)  
   - [5) Запуск локально](#5-запуск-локально)  
   - [6) Збірка релізу](#6-збірка-релізу)  
4. [🎯 Функціонал проєкту](#функціонал-проєкту)  
5. [🧪 Тестування](#тестування)  
   - [Unit-тести](#unit-тести)  
   - [Widget-тести](#widget-тести)  
   - [Integration-тести](#integration-тести)  
6. [🚀 CI/CD (GitHub Actions)](#ci/cd-github-actions)  
7. [📁 Структура проєкту](#структура-проєкту)  

---

## Огляд

**Social Photo Album** — це мобільний додаток, створений на Flutter, який дозволяє:

- Реєстрацію користувачів через Firebase Auth (Google Sign-In)  
- Завантаження фотографій з камери чи галереї  
- Створення/редагування альбомів та збереження у Firestore  
- Збереження фото у Firebase Storage  
- Додавання та перегляд коментарів під фото  
- Мультимовність (англійська та українська через easy_localization)  
- Підтримка світлої/темної теми (ThemeNotifier + Provider)  
- Локальне кешування завантажень (Hive) для offline-режиму  
- Набір тестів (unit, widget та integration)  

---

## Передумови

1. **Flutter SDK** (версія ≥ 3.8.0).  
2. **Dart SDK** (поставляється разом із Flutter).  
3. **Git** (для роботи з репозиторієм).  
4. **Підключення до Інтернету** (щоб завантажити залежності та підключитися до Firebase).  
5. **Android Studio** або **VS Code** (рекомендується для редагування Flutter-проектів).  
6. **Аккаунт Firebase** з налаштованим проєктом (додайте Android/iOS-додаток, отримаєте `google-services.json` і `GoogleService-Info.plist`).  

---

## Швидкий старт

### 1) Клонування репозиторію

Відкрийте термінал і виконайте:

```bash
git clone https://github.com/Lebedb23/social-photo-album-review1.git
cd social-photo-album-review1

2) Файл .env
У корені проєкту є шаблон .env.example. Скопіюйте його в .env і заповніть своїми значеннями:

bash
Копіювати
Редагувати
cp .env.example .env
Відкрийте файл .env і введіть:

env
Копіювати
Редагувати
# -----------------------------------------------------------------------------
# Приклад .env (повинно бути НЕ закомічено у репозиторій):
# -----------------------------------------------------------------------------

# Шлях до google-services.json для Android
ANDROID_GOOGLE_SERVICES_JSON=android/app/google-services.json

# Шлях до GoogleService-Info.plist для iOS
IOS_GOOGLE_SERVICES_PLIST=ios/Runner/GoogleService-Info.plist

# (Опціонально) Ваші конфіденційні ключі Firebase:
FIREBASE_API_KEY=YOUR_FIREBASE_API_KEY
FIREBASE_AUTH_DOMAIN=YOUR_AUTH_DOMAIN
FIREBASE_PROJECT_ID=YOUR_PROJECT_ID
FIREBASE_STORAGE_BUCKET=YOUR_STORAGE_BUCKET
FIREBASE_MESSAGING_SENDER_ID=YOUR_MESSAGING_SENDER_ID
FIREBASE_APP_ID=YOUR_APP_ID
Пояснення:

ANDROID_GOOGLE_SERVICES_JSON та IOS_GOOGLE_SERVICES_PLIST використовуються під час CI/CD або якщо ви бажаєте керувати шляхом до файлів через середовище.

Якщо ви не використовуєте ці змінні у коді (бо файли вже знаходяться у android/app/ та ios/Runner/), то цей крок можна пропустити або лишити як є.

3) Розміщення Firebase-файлів
Android: у Firebase Console створіть Android-додаток (Package name відповідає вашому Flutter-проекту). Завантажте google-services.json та помістіть його у:

bash
Копіювати
Редагувати
android/app/google-services.json
iOS: у Firebase Console створіть iOS-додаток (Bundle ID відповідає вашому Flutter-проекту). Завантажте GoogleService-Info.plist та помістіть його у:

swift
Копіювати
Редагувати
ios/Runner/GoogleService-Info.plist
Переконайтеся, що Android та iOS налаштовані на автоматичний запуск Firebase:

Android: у файлі android/build.gradle має бути:

groovy
Копіювати
Редагувати
buildscript {
  dependencies {
    classpath 'com.google.gms:google-services:4.3.15'
  }
}
а в android/app/build.gradle:

groovy
Копіювати
Редагувати
apply plugin: 'com.android.application'
apply plugin: 'com.google.gms.google-services'
iOS: у Xcode → Runner → “Build Phases” переконайтеся, що GoogleService-Info.plist додано до “Copy Bundle Resources”.

4) Інсталяція залежностей
bash
Копіювати
Редагувати
flutter pub get
Це завантажить усі необхідні пакети (Firebase, Provider, Hive, easy_localization, тощо).

5) Запуск локально
Підключіть фізичний пристрій або запустіть емулятор Android/iOS.

В терміналі виконайте:

bash
Копіювати
Редагувати
flutter run
Додаток завантажиться на ваш пристрій/емулятор.

Примітка:

Якщо ви використовуєте .env через flutter_dotenv, додайте у main.dart:

dart
Копіювати
Редагувати
import 'package:flutter_dotenv/flutter_dotenv.dart';
void main() async {
  await dotenv.load(fileName: '.env');
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await EasyLocalization.ensureInitialized();
  runApp(const MyApp());
}
У цьому проєкті основна логіка підключення Firebase вже є у main.dart, тому додаткове завантаження .env опціональне.

6) Збірка релізу
Android (APK):

bash
Копіювати
Редагувати
flutter build apk --release
Згенерований файл:

swift
Копіювати
Редагувати
build/app/outputs/flutter-apk/app-release.apk
iOS (IPA) (тільки на macOS):

bash
Копіювати
Редагувати
flutter build ios --release
Після цього відкрийте Xcode для генерації .ipa або передайте у TestFlight.

🎯 Функціонал проєкту
Реєстрація/авторизація

Google Sign-In (Firebase Auth)

Anonymous (якщо потрібно, але у цьому прикладі використовується Google)

Галерея

Завантаження фото з камери/галереї (image_picker)

Збереження у Firebase Storage, збереження метаданих (URL, createdAt) у Firestore

Альбоми

Створення нових альбомів (AlbumService + Firestore)

Редагування назви альбому

Видалення альбомів

Переміщення фото між галереєю та альбомами, збереження коментарів

Коментарі

Додавання коментарів до фото (BottomSheet із чатом)

Редагування/видалення коментарів

Локальне сховище (Offline)

Hive для кешування «відкладених» фото до завантаження (папка pendingPhotos)

При появі мережі синхронізуємо з Firebase

UI / UX

Інтерактивні елементи (ReorderableListView для альбомів на десктопі)

Drag & Drop фото для переміщення між альбомами

Анімації при завантаженні

Підтримка мультимовності (easy_localization)

Темна/світла тема (ThemeNotifier + Provider)

Тести

Unit-тести для сервісів (AlbumService, AuthService)

Widget-тести для ключових екранних віджетів (SignInPage, AlbumsPage)

Integration-тести для повного шляху авторизація→альбоми

🧪 Тестування
Unit-тести
У папці test/ є файл album_service_test.dart. Щоб запустити його:

bash
Копіювати
Редагувати
flutter test test/album_service_test.dart
Цей тест використовує fake_cloud_firestore замість реального Firestore, перевіряє:

Метод addAlbum правильно створює документ із полями title та createdAt.

Метод getAlbumsStream повертає порожній стрім, якщо ще не додано жодного альбому.

Якщо тести успішно пройшли, побачите:

makefile
Копіювати
Редагувати
00:XX +1: All tests passed!
Примітка:
Переконайтеся, що у pubspec.yaml у вас є:

yaml
Копіювати
Редагувати
dev_dependencies:
  flutter_test:
    sdk: flutter
  fake_cloud_firestore: ^2.5.2
А також виконайте:

bash
Копіювати
Редагувати
flutter pub get
Widget-тести
У папці test/ знаходиться sign_in_page_test.dart.
Цей тест перевіряє:

На SignInPage відображається одна кнопка ElevatedButton.

Текст кнопки локалізований (замінюється методом .tr()).

При натисканні викликається AuthService.signInWithGoogle() через мок GoogleSignIn.

Щоб запустити:

bash
Копіювати
Редагувати
flutter test test/sign_in_page_test.dart
Якщо тест пройшов, побачите:

makefile
Копіювати
Редагувати
00:XX +2: All tests passed!
Пояснення помилок, якщо є «LateInitializationError» від easy_localization
Widget-тести із easy_localization вимагають додати делегати:

dart
Копіювати
Редагувати
localizationsDelegates: [
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
  DefaultWidgetsLocalizations.delegate,
  DefaultMaterialLocalizations.delegate,
],
supportedLocales: [Locale('en'), Locale('uk')],
Це гарантує, що .tr() коректно працюватиме у тестовому середовищі.

Integration-тести
У папці integration_test/ є два файли:

app_test.dart (повний інтеграційний сценарій SignIn → Home)

albums_page_test.dart (перевірка того, що нажаль коректно відображається заголовок / кнопка «додати альбом»).

1) Встановіть емулятор Android або підключіть реальний пристрій
Переконайтеся, що:

bash
Копіювати
Редагувати
flutter devices
Показує ваш емулятор або підключений пристрій.

2) Запуск інтеграційного тесту
bash
Копіювати
Редагувати
flutter test integration_test/app_test.dart --dart-define=INTEGRATION_TEST=true
або просто

bash
Копіювати
Редагувати
flutter test integration_test/app_test.dart
Цей файл:

Виконує анонімний вхід (FirebaseAuth.signInAnonymously())

Переходить на SignInPage, натискає кнопку «Увійти через Google» (через mocks/або анонімний вхід)

Після успішного входу рендерить AlbumsPage

Перевіряє, що на екрані є кнопка «+» (додати альбом)

3) Запуск тесту для AlbumsPage
bash
Копіювати
Редагувати
flutter test integration_test/albums_page_test.dart
Цей тест:

Робить анонімний вхід у Firebase

Відкриває AlbumsPage

Перевіряє, що на екрані є локалізований текст "Мої альбоми" та іконка Icons.add

Успішний результат:

makefile
Копіювати
Редагувати
00:XX +1: All tests passed!
Примітка:
Якщо під час інтеграції падає помилка core/no-app (No Firebase App created), переконайтеся, що ви виконуєте Firebase.initializeApp() перед викликом будь-яких Firestore/Firestore-запитів. Зазвичай це реалізовано у main() вашого додатку.

🚀 CI/CD (GitHub Actions)
Щоб автоматизувати збірку, тестування та доставку додатку, налаштуємо GitHub Actions.

1) Створіть папку та файл
У вашому репозиторії створіть:

bash
Копіювати
Редагувати
.github/workflows/flutter_ci.yml
2) Вміст flutter_ci.yml
yaml
Копіювати
Редагувати
name: Flutter CI

on:
  push:
    branches:
      - main               # запустити на пуш до main
  pull_request:
    branches:
      - main

jobs:
  build-and-test:
    runs-on: ubuntu-latest
    env:
      TZ: 'Europe/Kiev'

    steps:
      # 1) Отримуємо код
      - name: Checkout repository
        uses: actions/checkout@v3

      # 2) Налаштування Flutter
      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          channel: 'stable'
          cache: true

      # 3) Кешування "pub" залежностей
      - name: Cache Pub dependencies
        uses: actions/cache@v3
        with:
          path: ~/.pub-cache
          key: ${{ runner.os }}-pub-${{ hashFiles('**/pubspec.yaml') }}
          restore-keys: |
            ${{ runner.os }}-pub-

      # 4) Отримання залежностей
      - name: Flutter pub get
        run: flutter pub get

      # 5) Аналіз коду (опціонально)
      - name: Flutter analyze
        run: flutter analyze

      # 6) Запуск unit & widget тестів
      - name: Run unit & widget tests
        run: flutter test --coverage

      # 7) (Опціонально) Запуск інтеграційних тестів
      # Якщо у вас налаштований емулятор чи використовується Firebase Testing Lab:
      # - name: Start Android emulator
      #   run: |
      #     echo "sdk.root=$(pwd)/android/sdk" >> $GITHUB_ENV
      #     sdkmanager "platform-tools" "platforms;android-30" "system-images;android-30;google_apis;x86"
      #     echo "no" | avdmanager create avd -n test -k "system-images;android-30;google_apis;x86"
      #     $ANDROID_HOME/emulator/emulator -avd test -no-window -no-audio &
      #     adb wait-for-device
      # - name: Run integration tests
      #   run: flutter test integration_test/app_test.dart --dart-define=INTEGRATION_TEST=true

      # 8) Збірка релізу (Android APK)
      - name: Build APK (release)
        run: flutter build apk --release

      # 9) Публікація артефакту (APK)
      - name: Upload APK artifact
        uses: actions/upload-artifact@v3
        with:
          name: app-release.apk
          path: build/app/outputs/flutter-apk/app-release.apk
Пояснення кроків:
Checkout repository — забираємо ваш код.

Set up Flutter — встановлюємо Flutter (stable-канал).

Cache Pub dependencies — кешуємо локальну папку ~/.pub-cache.

Flutter pub get — завантажуємо усі залежності.

Flutter analyze — аналіз коду (ліше якщо хочете перевірити style/lint).

Run unit & widget tests — виконуємо всі тести з test/.

(Опціонально) Інтеграційні тести — якщо хочете автоматично запускати emulator, є приклад у коментарях.

Build APK — збираємо app-release.apk.

Upload artifact — зберігаємо APK як артефакт workflow, щоб його можна було завантажити через GitHub Actions UI.

📁 Структура проєкту
bash
Копіювати
Редагувати
social_photo_album/
│
├── .github/
│   └── workflows/
│       └── flutter_ci.yml           # GitHub Actions workflow для CI/CD
│
├── android/
│   ├── app/
│   │   ├── build.gradle
│   │   ├── google-services.json     # Firebase Android config
│   │   └── …
│   └── …
│
├── assets/
│   └── translations/
│       ├── en.json                   # Англійські переклади
│       └── uk.json                   # Українські переклади
│
├── ios/
│   ├── Runner/
│   │   └── GoogleService-Info.plist  # Firebase iOS config
│   └── …
│
├── lib/
│   ├── main.dart
│   ├── auth_service.dart
│   ├── albums_page.dart
│   ├── sign_in_page.dart
│   ├── user_profile_page.dart
│   ├── theme_notifier.dart
│   ├── storage_service.dart
│   ├── album_service.dart
│   ├── widgets/
│   │   ├── album_tile.dart
│   │   ├── photo_tile.dart
│   │   └── …
│   ├── models/
│   │   └── photo_data.dart
│   └── …
│
├── pubspec.yaml
├── .env.example                     # Шаблон змінних середовища для Firebase
├── README.md                        # Ось цей файл
│
├── test/
│   ├── album_service_test.dart      # Unit-тест для AlbumService
│   └── sign_in_page_test.dart       # Widget-тест для SignInPage
│
├── integration_test/
│   ├── app_test.dart                # Integration-тест: SignIn → Home/Albums
│   └── albums_page_test.dart        # Integration-тест для AlbumsPage
│
└── …
🔚 Підсумок
Після клонування репозиторію і розміщення Firebase-файлів ви можете запустити локально проєкт через flutter run.

Unit- та widget-тести запускаються командою flutter test.

Integration-тести (якщо використовуєте емулятор) запускаються через flutter test integration_test/....

CI/CD за допомогою GitHub Actions автоматизує запуск тестів та збірку APK.

Якщо виникнуть питання або помилки під час налаштування, звертайтеся до розділу FAQ або створюйте Issue у репозиторії.