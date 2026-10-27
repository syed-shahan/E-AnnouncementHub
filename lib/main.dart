import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'screens/email_collection_screen.dart';
import 'screens/public_home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/user_dashboard_screen.dart';
import 'screens/post_announcement_screen.dart';
import 'screens/archive_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Safe Firebase init: will NOT crash if already initialized
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      Firebase.app(); // just use the existing default app
    }
  } catch (e) {
    // If hot restart or anything weird causes duplicate-app, just log and continue.
    debugPrint('Firebase init error (ignored if duplicate): $e');
  }

  runApp(const EAnnouncementHubApp());
}

class EAnnouncementHubApp extends StatelessWidget {
  const EAnnouncementHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-Announcement Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xfff5f5f7),
        useMaterial3: true,
      ),

      // ✅ Back to first-launch email collection logic
      home: const _InitialRouter(),

      routes: {
        '/email': (_) => const EmailCollectionScreen(),
        '/home': (_) => const PublicHomeScreen(),
        '/login': (_) => const LoginScreen(),
        '/admin': (_) => const AdminDashboardScreen(),
        '/user': (_) => const UserDashboardScreen(),
        '/archive': (_) => const ArchiveScreen(),
        // route used by Admin + User dashboards to post announcements
        '/post': (_) => const PostAnnouncementScreen(),
      },
    );
  }
}

/// Decides first screen:
/// - If first install → EmailCollectionScreen
/// - Else → PublicHomeScreen
class _InitialRouter extends StatelessWidget {
  const _InitialRouter();

  Future<bool> _shouldShowEmailScreen() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('hasCollectedEmail') ?? false);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _shouldShowEmailScreen(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final showEmail = snapshot.data!;
        if (showEmail) {
          return const EmailCollectionScreen();
        } else {
          return const PublicHomeScreen();
        }
      },
    );
  }
}