import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';

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
        // Main content — switch between pages
        body: TabBarView(
          physics: const NeverScrollableScrollPhysics(), // disable swipe
          children: [
            const AlbumsPage(),
            UserProfilePage(user: user),
          ],
        ),

        // Bottom tab bar
        bottomNavigationBar: Material(
          color: Colors.white,
          elevation: 8,
          child: TabBar(
            indicatorColor: Theme.of(context).primaryColor,
            indicatorWeight: 3,
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            labelPadding: const EdgeInsets.only(top: 4),
            tabs: [
              Tab(
                icon: const Icon(Icons.photo_album, size: 24),
                text: 'gallery'.tr(),
              ),
              Tab(
                icon: const Icon(Icons.person_outline, size: 24),
                text: 'profile'.tr(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
