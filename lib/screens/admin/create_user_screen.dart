// lib/screens/admin/create_user_screen.dart
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/floating_box.dart';

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final _emailC = TextEditingController();
  final _pwdC = TextEditingController();
  String _role = 'staff';
  bool _creating = false;

  int _priorityForRole(String role) {
    switch (role) {
      case 'principal':
        return 3;
      case 'hod':
        return 2;
      default:
        return 1; // staff
    }
  }

  Future<void> _create() async {
    final email = _emailC.text.trim();
    final pwd = _pwdC.text;
    if (email.isEmpty || pwd.isEmpty) {
      Fluttertoast.showToast(msg: 'Provide email & password', toastLength: Toast.LENGTH_SHORT);
      return;
    }
    setState(() => _creating = true);
    try {
      final users = FirebaseFirestore.instance.collection('users');
      // Check existing
      final exists = await users.where('email', isEqualTo: email).limit(1).get();
      if (exists.docs.isNotEmpty) {
        Fluttertoast.showToast(msg: 'User already exists', toastLength: Toast.LENGTH_SHORT);
        setState(() => _creating = false);
        return;
      }
      await users.add({
        'email': email,
        'password': pwd,
        'role': _role,
        'priority': _priorityForRole(_role),
        'createdAt': DateTime.now().toIso8601String(),
      });

      Fluttertoast.showToast(msg: 'User created', toastLength: Toast.LENGTH_SHORT);
      // after success show popup for 2s then go back
      await Future.delayed(const Duration(milliseconds: 500));
      Navigator.pop(context);
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed: $e', toastLength: Toast.LENGTH_LONG);
      setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(child: Image.asset('assets/college_bg.jpeg', fit: BoxFit.cover)),
          SafeArea(
            child: Center(
              child: FloatingBox(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/logo.png', height: 70),
                    const SizedBox(height: 12),
                    const Text('Create User', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(controller: _emailC, decoration: const InputDecoration(labelText: 'Email')),
                    const SizedBox(height: 8),
                    TextField(controller: _pwdC, decoration: const InputDecoration(labelText: 'Default Password')),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Radio<String>(value: 'staff', groupValue: _role, onChanged: (v) => setState(() => _role = v!)),
                        const Text('Staff'),
                        const SizedBox(width: 8),
                        Radio<String>(value: 'hod', groupValue: _role, onChanged: (v) => setState(() => _role = v!)),
                        const Text('HOD'),
                        const SizedBox(width: 8),
                        Radio<String>(value: 'principal', groupValue: _role, onChanged: (v) => setState(() => _role = v!)),
                        const Text('Principal'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _creating ? const CircularProgressIndicator() : ElevatedButton(onPressed: _create, child: const Text('Create')),
                    const SizedBox(height: 6),
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
