import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../widgets/branded_scaffold.dart';

class PostAnnouncementScreen extends StatefulWidget {
  const PostAnnouncementScreen({Key? key}) : super(key: key);

  @override
  State<PostAnnouncementScreen> createState() => _PostAnnouncementScreenState();
}

class _PostAnnouncementScreenState extends State<PostAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();

  bool _saving = false;
  String _selectedPriority = 'normal';
  List<String> _allowedPriorities = ['normal'];
  String _role = 'staff';

  @override
  void initState() {
    super.initState();
    // wait for first build so ModalRoute is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPermissions();
    });
  }

  List<String> _defaultAllowedForRole(String role) {
    switch (role) {
      case 'principal':
      case 'admin':
        return ['normal', 'repeated', 'important'];
      case 'hod':
        return ['normal', 'repeated', 'important'];
      case 'staff':
      default:
        return ['normal'];
    }
  }

  Future<void> _loadPermissions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    String role = (args?['role'] as String?) ?? 'staff';

    List<String> allowed;
    final rawPerms = args?['priorityPermissions'];
    if (rawPerms is List) {
      allowed = rawPerms.map((e) => e.toString()).toList();
    } else {
      allowed = _defaultAllowedForRole(role);
    }

    // Main admin always gets full permissions
    if (user.email == 'hydershahan2@gmail.com') {
      role = 'admin';
      allowed = _defaultAllowedForRole(role);
    }

    // If we still don't have anything useful, try Firestore once as a fallback
    if ((args == null || !args.containsKey('priorityPermissions')) ||
        allowed.isEmpty) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('admin_created_users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          role = (data['role'] as String?) ?? role;
          final p = data['priorityPermissions'];
          if (p is List) {
            allowed = p.map((e) => e.toString()).toList();
          } else {
            allowed = _defaultAllowedForRole(role);
          }
        }
      } catch (_) {
        // ignore and keep current role/allowed
      }
    }

    if (!mounted) return;
    setState(() {
      _role = role;
      _allowedPriorities = allowed.isEmpty ? ['normal'] : allowed;
      if (!_allowedPriorities.contains(_selectedPriority)) {
        _selectedPriority = _allowedPriorities.first;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _saving = true);

    try {
      await FirebaseFirestore.instance.collection('announcements').add({
        'title': _titleCtrl.text.trim(),
        'body': _bodyCtrl.text.trim(),
        'priority': _selectedPriority,
        'archived': false,
        'createdAt': FieldValue.serverTimestamp(),
        'createdByUid': user.uid,
        'createdByEmail': user.email ?? '',
        'createdByRole': _role,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Announcement posted')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to post: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BrandedScaffold(
      title: 'Post Announcement',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Text(
              'Role: $_role\nYou can post with priorities: '
              '${_allowedPriorities.join(', ').toUpperCase()}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bodyCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Body',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter announcement body' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedPriority,
              items: _allowedPriorities
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text(p.toUpperCase()),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (val == null) return;
                setState(() => _selectedPriority = val);
              },
              decoration: const InputDecoration(
                labelText: 'Priority',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _submit,
                icon: const Icon(Icons.send),
                label: _saving
                    ? const Text('Posting...')
                    : const Text('Post Announcement'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
