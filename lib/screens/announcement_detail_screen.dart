// lib/screens/announcement_detail_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AnnouncementDetailScreen extends StatelessWidget {
  final String documentId;
  const AnnouncementDetailScreen({Key? key, required this.documentId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (documentId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Announcement')),
        body: const Center(child: Text('No announcement ID provided.')),
      );
    }

    final docRef = FirebaseFirestore.instance.collection('announcements').doc(documentId);

    return Scaffold(
      appBar: AppBar(title: const Text('Announcement')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: docRef.snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());

          final data = snap.data!.data() as Map<String, dynamic>?;

          if (data == null) {
            return const Center(child: Text('Announcement not found.'));
          }

          final title = data['title'] ?? 'Untitled';
          final description = data['description'] ?? '';
          final createdAt = data['createdAt'];
          final priority = data['priority']?.toString() ?? '-';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text('Priority: $priority', style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  if (createdAt != null) Text('Created: $createdAt', style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 12),
                  Text(description, style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
