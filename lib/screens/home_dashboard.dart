import 'package:flutter/material.dart';
import 'add_user_screen.dart';
import 'approve_emails_screen.dart';
import '../widgets/floating_box.dart';
import 'post_announcement_screen.dart';

class HomeDashboard extends StatelessWidget {
  HomeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FloatingBox(
        child: Column(
          children: [
            const Text('Admin / User Dashboard', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddUserScreen())),
              child: const Text('Add User'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ApproveEmailsScreen())),
              child: const Text('Approve Pending Emails'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PostAnnouncementScreen())),
              child: const Text('Post Announcement'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                // logout returns to public home
                Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
              },
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
