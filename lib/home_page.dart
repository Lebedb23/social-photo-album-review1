// lib/home_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'albums_page.dart';
import 'user_profile_page.dart';

class HomePage extends StatelessWidget {
  final User user;
  const HomePage({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        // Основний контент — перегортання між сторінками
        body: TabBarView(
          physics: const NeverScrollableScrollPhysics(), // щоб не свайпалось
          children: [
            const AlbumsPage(),
            UserProfilePage(user: user),
          ],
        ),

        // Нижня панель із вкладками
        bottomNavigationBar: Material(
          color: Colors.white,
          elevation: 8,
          child: TabBar(
            // Вирівнюємо таби по центру іконками та підписами
            indicatorColor: Theme.of(context).primaryColor,
            indicatorWeight: 3,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            labelPadding: const EdgeInsets.only(top: 4),
            tabs: const [
              Tab(
                icon: Icon(Icons.photo_album, size: 24),
                text: 'Галерея',
              ),
              Tab(
                icon: Icon(Icons.person_outline, size: 24),
                text: 'Профіль',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
