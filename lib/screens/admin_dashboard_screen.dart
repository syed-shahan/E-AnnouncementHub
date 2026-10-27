// lib/screens/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../widgets/branded_scaffold.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _loading = false;

  static const String _adminEmail = 'hydershahan2@gmail.com';
  static const String _adminPassword = 'admin1234';

  bool get _isAdmin =>
      _auth.currentUser != null && _auth.currentUser!.email == _adminEmail;

  Future<void> _approvePendingEmail(String docId, String email) async {
    setState(() => _loading = true);
    try {
      final batch = _db.batch();
      final pendingRef = _db.collection('pending_emails').doc(docId);
      final approvedRef = _db.collection('approved_emails').doc();

      batch.set(approvedRef, {
        'email': email,
        'approvedAt': FieldValue.serverTimestamp(),
      });
      batch.delete(pendingRef);

      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Approved $email')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Approve failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _createAdminUserDialog() async {
    if (!_isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only main admin can create users')),
      );
      return;
    }

    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String role = 'staff';

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Create User (Staff/HOD/Principal)'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: passCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Password (min 6 chars)',
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                  ),
                  onChanged: (v) => role = v ?? 'staff',
                  items: const [
                    DropdownMenuItem(
                      value: 'staff',
                      child: Text('Staff'),
                    ),
                    DropdownMenuItem(
                      value: 'hod',
                      child: Text('HOD'),
                    ),
                    DropdownMenuItem(
                      value: 'principal',
                      child: Text('Principal'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            TextButton(
              child: const Text('Create'),
              onPressed: () async {
                final email = emailCtrl.text.trim();
                final pass = passCtrl.text;

                if (email.isEmpty || pass.isEmpty) return;
                if (pass.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password must be at least 6 characters'),
                    ),
                  );
                  return;
                }

                Navigator.of(ctx).pop();
                await _createAdminUser(email, pass, role);
              },
            ),
          ],
        );
      },
    );
  }

  /// Create user (staff/HOD/principal) via Firebase Auth
  /// and also store role in `admin_created_users`.
  Future<void> _createAdminUser(
      String email, String password, String role) async {
    setState(() => _loading = true);
    try {
      // 1) Create user (this will log us in as that user)
      final UserCredential newCred =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final String newUid = newCred.user!.uid;

      // Decide allowed priorities based on role
      List<String> priorityPermissions;
      switch (role) {
        case 'principal':
          priorityPermissions = ['normal', 'repeated', 'important'];
          break;
        case 'hod':
          // HOD also allowed IMPORTANT
          priorityPermissions = ['normal', 'repeated', 'important'];
          break;
        case 'staff':
        default:
          priorityPermissions = ['normal'];
      }

      // 2) Store metadata
      await _db.collection('admin_created_users').doc(newUid).set({
        'email': email,
        'role': role,
        'createdBy': _adminEmail,
        'createdAt': FieldValue.serverTimestamp(),
        'priorityPermissions': priorityPermissions,
      });

      // 3) Sign back as main admin so admin session is restored
      await FirebaseAuth.instance.signOut();
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _adminEmail,
        password: _adminPassword,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Created user $email as $role')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Create user failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
  }

  void _openPostScreen([String? role, List<String>? priorityPermissions]) {
    Navigator.of(context).pushNamed(
      '/post',
      arguments: {
        if (role != null) 'role': role,
        if (priorityPermissions != null)
          'priorityPermissions': priorityPermissions,
      },
    );
  }

  Widget _pendingEmailList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('pending_emails')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(),
          );
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('No pending emails'),
          );
        }
        final docs = snap.data!.docs;
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, idx) {
            final d = docs[idx];
            final data = d.data() as Map<String, dynamic>;
            final email = data['email'] ?? '';
            return ListTile(
              title: Text(email),
              trailing: ElevatedButton(
                onPressed: _loading
                    ? null
                    : () => _approvePendingEmail(d.id, email),
                child: const Text('Approve'),
              ),
            );
          },
        );
      },
    );
  }

  Widget _adminCreatedUsersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('admin_created_users')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(),
          );
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('No admin-created users'),
          );
        }
        final docs = snap.data!.docs;
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, idx) {
            final doc = docs[idx];
            final data = doc.data() as Map<String, dynamic>;
            final email = data['email'] ?? '';
            final String role = (data['role'] ?? 'staff').toString();

            List<String>? perms;
            final rawPerms = data['priorityPermissions'];
            if (rawPerms is List) {
              perms = rawPerms.map((e) => e.toString()).toList();
            }

            return ListTile(
              title: Text(email),
              subtitle: Text('Role: $role'),
              trailing: IconButton(
                icon: const Icon(Icons.post_add),
                onPressed: () => _openPostScreen(role, perms),
                tooltip: 'Post as $role',
              ),
            );
          },
        );
      },
    );
  }

  Widget _announcementsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('announcements')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(),
          );
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('No announcements yet'),
          );
        }
        final docs = snap.data!.docs;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            return ListTile(
              title: Text(d['title'] ?? ''),
              subtitle: Text(d['body'] ?? ''),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // If somehow non-admin reaches here, just show message on same UI.
    if (!_isAdmin) {
      return BrandedScaffold(
        title: 'Admin Dashboard',
        child: const Center(
          child: Text(
            'Admin only area.\nLogin as admin to access dashboard.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return BrandedScaffold(
      title: 'Admin Dashboard',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _loading ? null : _createAdminUserDialog,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Create User'),
                ),
                ElevatedButton.icon(
                  onPressed: _loading ? null : () => _openPostScreen('admin'),
                  icon: const Icon(Icons.post_add),
                  label: const Text('Post Announcement'),
                ),
                ElevatedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ExpansionTile(
              title: const Text('Pending Emails (to approve)'),
              children: [
                _pendingEmailList(),
              ],
            ),
            ExpansionTile(
              title: const Text('Admin-Created Users'),
              children: [
                _adminCreatedUsersList(),
              ],
            ),
            ExpansionTile(
              title: const Text('Recent Announcements'),
              children: [
                _announcementsList(),
              ],
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}
