import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'firebase_options.dart';
import 'auth_service.dart';
import 'storage_service.dart';
import 'albums_page.dart';
import 'home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
      ),
      home: const AuthWrapper(),
    );
  }
}

/// Обгортає весь додаток, показує чи SignInPage, чи HomePage
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          if (user == null) {
            return const SignInPage();
          } else {
            return HomePage(user: user);
          }
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});
  @override
  Widget build(BuildContext c) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final user = await AuthService().signInWithGoogle();
            if (user == null) {
              ScaffoldMessenger.of(
                c,
              ).showSnackBar(const SnackBar(content: Text('Вхід скасовано')));
            }
          },
          child: const Text('Увійти через Google'),
        ),
      ),
    );
  }
}

class UserProfilePage extends StatefulWidget {
  final User user;
  const UserProfilePage({super.key, required this.user});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final StorageService _storageService = StorageService();
  Uint8List? _imageBytes;

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    try {
      final bytes = await picked.readAsBytes();
      final url = await _storageService.uploadImage(bytes, widget.user.uid);
      setState(() => _imageBytes = bytes);
      print('Фото завантажено: $url');
    } catch (e) {
      print('Помилка при завантаженні: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatar = _imageBytes != null
        ? Image.memory(_imageBytes!, width: 150, height: 150, fit: BoxFit.cover)
        : (widget.user.photoURL != null
              ? CircleAvatar(
                  backgroundImage: NetworkImage(widget.user.photoURL!),
                  radius: 50,
                )
              : const Icon(Icons.account_circle, size: 100));

    return Scaffold(
      appBar: AppBar(
        title: Text('Привіт, ${widget.user.displayName ?? 'користувач'}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService().signOut(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            avatar,
            const SizedBox(height: 20),
            Text('Email: ${widget.user.email ?? 'не вказано'}'),
            ElevatedButton(
              onPressed: _pickAndUploadImage,
              child: const Text('Завантажити нове фото'),
            ),
          ],
        ),
      ),
    );
  }
}
