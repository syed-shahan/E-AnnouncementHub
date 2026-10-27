import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/floating_box.dart';

class ChangePasswordScreen extends StatefulWidget {
  final String userDocId;
  final String userId;
  const ChangePasswordScreen({super.key, required this.userDocId, required this.userId});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _pw = TextEditingController();
  final _pw2 = TextEditingController();
  bool _saving = false;

  Future<void> change() async {
    final p1 = _pw.text;
    final p2 = _pw2.text;
    if (p1.isEmpty || p2.isEmpty || p1 != p2) {
      Fluttertoast.showToast(msg: 'Passwords must match', toastLength: Toast.LENGTH_SHORT);
      return;
    }
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.userDocId).update({
        'password': p1,
        'mustChange': false,
        'failed': 0,
      });
      Fluttertoast.showToast(msg: 'Password changed', toastLength: Toast.LENGTH_SHORT);
      Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e', toastLength: Toast.LENGTH_LONG);
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FloatingBox(
        child: Column(
          children: [
            Text('Change password for ${widget.userId}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            TextField(controller: _pw, obscureText: true, decoration: const InputDecoration(hintText: 'New password')),
            const SizedBox(height: 8),
            TextField(controller: _pw2, obscureText: true, decoration: const InputDecoration(hintText: 'Confirm password')),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _saving ? null : change, child: _saving ? const CircularProgressIndicator() : const Text('Save')),
          ],
        ),
      ),
    );
  }
}
