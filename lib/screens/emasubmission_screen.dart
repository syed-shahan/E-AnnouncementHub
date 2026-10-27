// lib/screens/email_submission_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EmailSubmissionScreen extends StatefulWidget {
  const EmailSubmissionScreen({super.key});
  @override
  State<EmailSubmissionScreen> createState() => _EmailSubmissionScreenState();
}

class _EmailSubmissionScreenState extends State<EmailSubmissionScreen> {
  final ctrl = TextEditingController();
  bool saving = false;

  Future<void> _submit() async {
    final e = ctrl.text.trim().toLowerCase();
    if (e.isEmpty || !e.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter valid email')));
      return;
    }
    setState(() => saving = true);
    try {
      await FirebaseFirestore.instance.collection('pending_emails').add({
        'email': e,
        'createdAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Submitted — awaiting admin approval')));
      ctrl.clear();
    } catch (ex) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $ex')));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  void dispose() { ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Email')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Email')),
          const SizedBox(height:12),
          FilledButton(onPressed: saving ? null : _submit, child: saving ? const CircularProgressIndicator() : const Text('Submit')),
        ]),
      ),
    );
  }
}
