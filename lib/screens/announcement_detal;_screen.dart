// lib/screens/announcement_detail_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AnnouncementDetailScreen extends StatefulWidget {
  final String documentId;
  const AnnouncementDetailScreen({Key? key, required this.documentId}) : super(key: key);

  @override
  State<AnnouncementDetailScreen> createState() => _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState extends State<AnnouncementDetailScreen> {
  DocumentSnapshot<Map<String, dynamic>>? _doc;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDoc();
  }

  Future<void> _loadDoc() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('announcements')
          .doc(widget.documentId)
          .get();
      if (!mounted) return;
      setState(() {
        _doc = snap as DocumentSnapshot<Map<String, dynamic>>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Announcement')),
        body: Center(child: Text('Error: $_error')),
      );
    }
    final data = _doc?.data() ?? <String, dynamic>{};
    final title = data['title'] ?? 'Untitled';
    final desc = data['description'] ?? '';
    final createdAt = data['createdAt'];
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            if (createdAt != null) Text('Created: $createdAt', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 12),
            Text(desc, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
