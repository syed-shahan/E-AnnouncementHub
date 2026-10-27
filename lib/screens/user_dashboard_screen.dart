import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/branded_scaffold.dart';

class _PostingInfo {
  final bool canPost;
  final String? role;
  final List<String>? priorityPermissions;

  _PostingInfo({
    required this.canPost,
    this.role,
    this.priorityPermissions,
  });
}

class UserDashboardScreen extends StatelessWidget {
  const UserDashboardScreen({super.key});

  Future<_PostingInfo> _loadPostingInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _PostingInfo(canPost: false);
    }

    final doc = await FirebaseFirestore.instance
        .collection('admin_created_users')
        .doc(user.uid)
        .get();

    if (!doc.exists) {
      // not an admin-created user → view-only access
      return _PostingInfo(canPost: false);
    }

    final data = doc.data() as Map<String, dynamic>;
    final role = (data['role'] as String?) ?? 'staff';

    List<String> perms;
    final rawPerms = data['priorityPermissions'];
    if (rawPerms is List) {
      perms = rawPerms.map((e) => e.toString()).toList();
    } else {
      // fallback based on role
      switch (role) {
        case 'principal':
        case 'admin':
          perms = ['normal', 'repeated', 'important'];
          break;
        case 'hod':
          perms = ['normal', 'repeated', 'important'];
          break;
        default:
          perms = ['normal'];
      }
    }

    return _PostingInfo(
      canPost: true,
      role: role,
      priorityPermissions: perms,
    );
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'User';

    return BrandedScaffold(
      title: 'User Dashboard',
      child: FutureBuilder<_PostingInfo>(
        future: _loadPostingInfo(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, $email',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                const LinearProgressIndicator(),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _logout(context),
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                  ),
                ),
              ],
            );
          }

          final info = snapshot.data!;
          final canPost = info.canPost;
          final role = info.role ?? 'staff';
          final perms = info.priorityPermissions ?? const ['normal'];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, $email',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              if (canPost)
                Text(
                  'You can view announcements on the public screen and also '
                  'post announcements.\n\n'
                  'Role: $role\n'
                  'Allowed priorities: ${perms.join(', ').toUpperCase()}',
                )
              else
                const Text(
                  'You can view announcements on the public screen.\n'
                  'If admin gives you extra permissions, they will reflect here later.\n\n'
                  'Currently you have view-only access.\n'
                  'Ask admin to enable posting permissions for your account.',
                ),
              const Spacer(),
              if (canPost)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        '/post',
                        arguments: {
                          'role': role,
                          'priorityPermissions': perms,
                        },
                      );
                    },
                    icon: const Icon(Icons.post_add),
                    label: const Text('Post Announcement'),
                  ),
                ),
              if (canPost) const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
