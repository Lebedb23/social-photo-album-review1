// lib/user_profile_page.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'storage_service.dart';
import 'auth_service.dart';
import 'package:easy_localization/easy_localization.dart';

class UserProfilePage extends StatefulWidget {
  final User user;
  const UserProfilePage({Key? key, required this.user}) : super(key: key);

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final _storageService = StorageService();
  Uint8List? _imageBytes;

  Future<void> _pickAndUploadImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final url = await _storageService.uploadImage(bytes, widget.user.uid);
    await FirebaseAuth.instance.currentUser!.updatePhotoURL(url);
    await FirebaseAuth.instance.currentUser!.reload();
    setState(() => _imageBytes = bytes);
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = FirebaseAuth.instance.currentUser?.photoURL;
    final avatar = _imageBytes != null
        ? Image.memory(_imageBytes!, width: 150, height: 150, fit: BoxFit.cover)
        : (photoUrl != null
              ? CircleAvatar(
                  backgroundImage: NetworkImage(photoUrl),
                  radius: 50,
                )
              : const Icon(Icons.account_circle, size: 100));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 20),
          avatar,
          const SizedBox(height: 20),
          Text('email'.tr(args: [widget.user.email ?? tr('not_specified')])),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _pickAndUploadImage,
            child: Text('change_photo'.tr()),
          ),
          ListTile(
            title: Text('language'.tr()),
            trailing: DropdownButton<Locale>(
              value: context.locale,
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
              onChanged: (Locale? locale) {
                if (locale != null) {
                  context.setLocale(locale);
                }
              },
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.logout),
            label: Text('logout'.tr()),
            onPressed: () async {
              await AuthService().signOut();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          ),
        ],
      ),
    );
  }
}
