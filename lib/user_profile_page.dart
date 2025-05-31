// lib/user_profile_page.dart

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:easy_localization/easy_localization.dart';

import 'storage_service.dart';
import 'auth_service.dart';
import 'theme_notifier.dart';

class UserProfilePage extends StatefulWidget {
  final User user;
  const UserProfilePage({Key? key, required this.user}) : super(key: key);

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final StorageService _storageService = StorageService();
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    // Автоматично пробуємо синхронізувати “чергу” при відкритті сторінки
    _syncPendingPhotos();
  }

  /// Якщо є інтернет — відразу завантажуємо фото в Firebase,
  /// якщо ні — відкладаємо шлях у Hive
  Future<void> _pickAndUploadImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final filePath = picked.path;
    final box = Hive.box<String>('pendingPhotos');

    try {
      // 1) Завантаження байтів у Storage
      final bytes = await picked.readAsBytes();
      final url = await _storageService.uploadImage(bytes, widget.user.uid);

      // 2) Запис у Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .collection('photos')
          .add({
        'url': url,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('photo_uploaded'.tr())),
      );
      setState(() => _imageBytes = bytes);
    } catch (e) {
      // Якщо offline або інша помилка — відкладаємо в Hive
      await box.add(filePath);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('offline_photo_queued'.tr())),
      );
    }
  }

  /// Синхронізуємо всі шляхи з Hive → Firebase (якщо інтернет з’явився)
  Future<void> _syncPendingPhotos() async {
    final box = Hive.box<String>('pendingPhotos');
    final keys = box.keys.cast<int>().toList();

    for (final key in keys) {
      final localPath = box.get(key);
      if (localPath == null) continue;

      try {
        final bytes = await File(localPath).readAsBytes();
        final url = await _storageService.uploadImage(bytes, widget.user.uid);

        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.user.uid)
            .collection('photos')
            .add({
          'url': url,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Після успіху видаляємо з Hive
        await box.delete(key);
      } catch (e) {
        // Якщо досі offline — лишаємо елемент у черзі
        continue;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeNotifier>().mode == ThemeMode.dark;

    final photoUrl = FirebaseAuth.instance.currentUser?.photoURL;
    final avatar = _imageBytes != null
        ? ClipOval(
            child: Image.memory(
              _imageBytes!,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          )
        : (photoUrl != null
            ? CircleAvatar(
                backgroundImage: NetworkImage(photoUrl),
                radius: 50,
              )
            : const Icon(Icons.account_circle, size: 100));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          // 🖼 Аватар
          avatar,
          const SizedBox(height: 12),

          // 📸 Кнопка "Змінити фото"
          ElevatedButton(
            onPressed: _pickAndUploadImage,
            child: Text('change_photo'.tr()),
          ),

          const SizedBox(height: 20),
          // ✉️ Показуємо email
          Column(
            children: [
              Text('email_label'.tr(),
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 4),
              Text(
                widget.user.email ?? tr('not_specified'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),

          const SizedBox(height: 30),
          // 🌐 Dropdown вибору мови
          Center(
            child: DropdownButton<Locale>(
              value: context.locale,
              underline: const SizedBox(),
              style: Theme.of(context).textTheme.titleMedium,
              items: [
                DropdownMenuItem(
                  value: const Locale('uk'),
                  child: Text('ukrainian'.tr()),
                ),
                DropdownMenuItem(
                  value: const Locale('en'),
                  child: Text('english'.tr()),
                ),
              ],
              onChanged: (locale) {
                if (locale != null) context.setLocale(locale);
              },
            ),
          ),

          const SizedBox(height: 30),
          // ⛅ Тема: показуємо лише “ніч” або “день”
          Center(
            child: Text(
              isDark ? 'theme_night'.tr() : 'theme_day'.tr(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 8),
          // 🔀 Перемикач теми
          Center(
            child: Switch(
              value: isDark,
              onChanged: (val) =>
                  context.read<ThemeNotifier>().toggleTheme(val),
            ),
          ),

          const SizedBox(height: 40),
          // ❇️ (опціонально) Кнопка ручної синхронізації
          ElevatedButton(
            onPressed: _syncPendingPhotos,
            child: Text('sync_offline_photos'.tr()),
          ),

          const SizedBox(height: 20),
          // 🚪 Кнопка Logout (в самому низу)
          ElevatedButton.icon(
            icon: const Icon(Icons.logout),
            label: Text('logout'.tr()),
            onPressed: () async {
              await AuthService().signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }
}
