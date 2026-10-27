import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/floating_box.dart';
import 'login_screen.dart';
import 'archive_screen.dart';
import 'post_announcement_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool loggedIn = false;
  String loggedUserId = '';
  String loggedRole = '';

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('loggedUserId');
    final role = prefs.getString('loggedUserRole');
    setState(() {
      loggedIn = id != null;
      loggedUserId = id ?? '';
      loggedRole = role ?? '';
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('loggedUserId');
    await prefs.remove('loggedUserRole');
    setState(() {
      loggedIn = false;
      loggedUserId = '';
      loggedRole = '';
    });
  }

  bool get canPost => loggedIn; // only logged-in users can post
  bool get canPostImportant => loggedRole == 'hod' || loggedRole == 'principal' || loggedRole == 'admin';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // background
          SizedBox.expand(child: Image.asset('assets/college_bg.jpeg', fit: BoxFit.cover)),
          // floating box with announcements
          Center(
            child: FloatingBox(
              child: Column(
                children: [
                  const SizedBox(height: 6),
                  Image.asset('assets/logo.png', height: 60, fit: BoxFit.contain),
                  const SizedBox(height: 8),
                  const Text('Announcements', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('announcements').orderBy('timestamp', descending: true).snapshots(),
                      builder: (context, snap) {
                        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                        final docs = snap.data!.docs;
                        if (docs.isEmpty) return const Center(child: Text('No announcements yet'));
                        return ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (context, i) {
                            final d = docs[i].data() as Map<String, dynamic>;
                            return Card(
                              child: ListTile(
                                title: Text(d['title'] ?? ''),
                                subtitle: Text(d['body'] ?? ''),
                                trailing: Text(d['priority'] ?? ''),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          // archive button bottom-left
          Positioned(
            bottom: 20,
            left: 20,
            child: FloatingActionButton(
              heroTag: 'archive',
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ArchiveScreen())),
              child: const Icon(Icons.archive),
            ),
          ),
          // login/post buttons bottom-right
          Positioned(
            bottom: 20,
            right: 20,
            child: Column(
              children: [
                if (canPost)
                  FloatingActionButton(
                    heroTag: 'post',
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => PostAnnouncementScreen(userId: loggedUserId, canPostImportant: canPostImportant)));
                    },
                    child: const Icon(Icons.add),
                  ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: 'loginLogout',
                  onPressed: loggedIn ? _logout : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                  backgroundColor: loggedIn ? Colors.red : null,
                  child: Icon(loggedIn ? Icons.logout : Icons.login),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
