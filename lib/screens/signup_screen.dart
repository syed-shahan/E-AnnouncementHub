import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PublicHomeScreen extends StatelessWidget {
  const PublicHomeScreen({Key? key}) : super(key: key);

  Stream<QuerySnapshot> _announcementsStream() {
    return FirebaseFirestore.instance
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Safe helper: avoids int→String crash
  String _readString(Map<String, dynamic> data, String key,
      {String fallback = ''}) {
    final value = data[key];
    if (value == null) return fallback;
    if (value is String) return value;
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // real UI is inside the Stack
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/bg.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // Light overlay so cards are readable
          Positioned.fill(
            child: Container(
              color: Colors.white.withOpacity(0.86),
            ),
          ),
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: logo + title
                  Row(
                    children: [
                      Image.asset(
                        'assets/logo.png',
                        height: 40,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Public Announcements',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Archive + Login pills
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _pillButton(
                        icon: Icons.archive_outlined,
                        label: 'Archive',
                        onTap: () =>
                            Navigator.of(context).pushNamed('/archive'),
                      ),
                      _pillButton(
                        icon: Icons.login,
                        label: 'Login',
                        onTap: () =>
                            Navigator.of(context).pushNamed('/login'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Latest Announcements',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Announcements list
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _announcementsStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return const Center(
                            child: Text(
                              'Error loading announcements',
                              style: TextStyle(color: Colors.red),
                            ),
                          );
                        }

                        if (!snapshot.hasData ||
                            snapshot.data!.docs.isEmpty) {
                          return const Center(
                            child: Text('No announcements yet'),
                          );
                        }

                        final docs = snapshot.data!.docs;

                        return ListView.separated(
                          padding: const EdgeInsets.only(top: 8, bottom: 16),
                          itemCount: docs.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            try {
                              final raw = docs[index].data();
                              final Map<String, dynamic> data =
                                  raw is Map<String, dynamic>
                                      ? raw
                                      : <String, dynamic>{};

                              final title =
                                  _readString(data, 'title').trim();
                              final body =
                                  _readString(data, 'body').trim();
                              final priority = _readString(
                                      data, 'priority',
                                      fallback: 'normal')
                                  .toLowerCase();

                              return _announcementCard(
                                title:
                                    title.isEmpty ? 'Untitled' : title,
                                body: body,
                                priority: priority,
                              );
                            } catch (e) {
                              // Skip bad doc but keep UI alive
                              debugPrint(
                                  'Error building announcement card: $e');
                              return const SizedBox.shrink();
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- UI helpers (match your card / pill style) ----------

  Widget _pillButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.deepPurple),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.deepPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _announcementCard({
    required String title,
    required String body,
    required String priority, // normal / important / etc.
  }) {
    final chipText = priority.toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Priority chip
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              chipText,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
