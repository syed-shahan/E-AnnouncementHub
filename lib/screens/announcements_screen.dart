import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './post_announcement_screen.dart';

class AnnouncementsScreen extends StatelessWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            child: const Icon(Icons.login),
            onPressed: () => Navigator.pushNamed(context, '/login'),
          ),
          const SizedBox(height: 8),
          if (user != null)
            FloatingActionButton(
              child: const Icon(Icons.add),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PostAnnouncementScreen()),
              ),
            ),
        ],
      ),
      body: _bg(
        child: StreamBuilder(
          stream: FirebaseFirestore.instance.collection("announcements").orderBy("time", descending: true).snapshots(),
          builder: (c, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());

            final docs = snap.data!.docs;
            return ListView.builder(
              itemCount: docs.length,
              itemBuilder: (_, i) {
                final a = docs[i];
                return _card(
                  ListTile(
                    title: Text(a["title"]),
                    subtitle: Text(a["desc"]),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _bg({required Widget child}) => Container(
    decoration: const BoxDecoration(
      image: DecorationImage(image: AssetImage("assets/college_bg.jpeg"), fit: BoxFit.cover),
    ),
    child: child,
  );

  Widget _card(Widget child) => Container(
    margin: const EdgeInsets.all(12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(.85),
      borderRadius: BorderRadius.circular(10),
    ),
    child: child,
  );
}
