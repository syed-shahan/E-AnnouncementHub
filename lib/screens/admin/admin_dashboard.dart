// lib/screens/admin/admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../widgets/floating_box.dart';
import 'create_user_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // keep consistent overall look
      body: Stack(
        children: [
          SizedBox.expand(child: Image.asset('assets/college_bg.jpeg', fit: BoxFit.cover)),
          SafeArea(
            child: Center(
              child: FloatingBox(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/logo.png', height: 70, fit: BoxFit.contain),
                    const SizedBox(height: 12),
                    const Text('Admin Dashboard', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateUserScreen()));
                      },
                      icon: const Icon(Icons.person_add),
                      label: const Text('Add User'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        // open approved emails panel or other admin functions
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ApprovedEmailsScreen()));
                      },
                      icon: const Icon(Icons.mail),
                      label: const Text('Approve Emails'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        // logout to public home
                        Fluttertoast.showToast(msg: 'Logged out', toastLength: Toast.LENGTH_SHORT);
                        Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Minimal ApprovedEmailsScreen inline to avoid "missing file" errors
class ApprovedEmailsScreen extends StatelessWidget {
  ApprovedEmailsScreen({super.key});
  final CollectionReference pending = FirebaseFirestore.instance.collection('pending_emails');
  final CollectionReference approved = FirebaseFirestore.instance.collection('approved_emails');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pending Emails')),
      body: StreamBuilder<QuerySnapshot>(
        stream: pending.snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No pending emails.'));
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final id = docs[i].id;
              final email = data['email'] ?? '';
              return ListTile(
                title: Text(email),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () async {
                      // move to approved
                      await approved.add({'email': email, 'approvedAt': DateTime.now().toIso8601String()});
                      await pending.doc(id).delete();
                      Fluttertoast.showToast(msg: 'Approved $email', toastLength: Toast.LENGTH_SHORT);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await pending.doc(id).delete();
                      Fluttertoast.showToast(msg: 'Removed', toastLength: Toast.LENGTH_SHORT);
                    },
                  ),
                ]),
              );
            },
          );
        },
      ),
    );
  }
}
