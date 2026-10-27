// lib/screens/admin/admin_login_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../widgets/floating_box.dart'; // your floating box widget path

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final TextEditingController _emailC = TextEditingController();
  final TextEditingController _pwdC = TextEditingController();
  bool _loading = false;

  Future<void> _login() async {
    final email = _emailC.text.trim();
    final pwd = _pwdC.text;
    if (email.isEmpty || pwd.isEmpty) {
      Fluttertoast.showToast(msg: 'Enter both email and password', toastLength: Toast.LENGTH_SHORT);
      return;
    }
    setState(() => _loading = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .where('password', isEqualTo: pwd)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        Fluttertoast.showToast(msg: 'Invalid credentials', toastLength: Toast.LENGTH_SHORT);
        setState(() => _loading = false);
        return;
      }

      final user = snap.docs.first.data();
      if (user['role'] != 'admin') {
        Fluttertoast.showToast(msg: 'Only admin allowed here', toastLength: Toast.LENGTH_SHORT);
        setState(() => _loading = false);
        return;
      }

      Fluttertoast.showToast(msg: 'Welcome admin', toastLength: Toast.LENGTH_SHORT);
      // navigate to admin dashboard
      Navigator.pushReplacementNamed(context, '/admin/dashboard');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Login failed: $e', toastLength: Toast.LENGTH_LONG);
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keep your floating box UI consistent
    return Scaffold(
      body: Stack(
        children: [
          // background
          SizedBox.expand(
            child: Image.asset('assets/college_bg.jpeg', fit: BoxFit.cover),
          ),
          SafeArea(
            child: Center(
              child: FloatingBox(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/logo.png', height: 70, fit: BoxFit.contain),
                    const SizedBox(height: 12),
                    const Text('Admin Login', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(controller: _emailC, decoration: const InputDecoration(labelText: 'Email')),
                    const SizedBox(height: 8),
                    TextField(controller: _pwdC, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
                    const SizedBox(height: 12),
                    _loading
                        ? const CircularProgressIndicator()
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(onPressed: _login, child: const Text('Login')),
                              OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Back')),
                            ],
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
