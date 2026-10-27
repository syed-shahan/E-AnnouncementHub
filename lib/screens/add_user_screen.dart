import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../widgets/floating_box.dart';
import '../services/firestore_service.dart';

class AddUserScreen extends StatefulWidget {
  AddUserScreen({super.key});
  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final idCtrl = TextEditingController();
  final roleCtrl = TextEditingController();
  bool saving = false;

  Future<void> saveUser() async {
    final id = idCtrl.text.trim();
    final role = roleCtrl.text.trim().toLowerCase();
    if (id.isEmpty || role.isEmpty) {
      Fluttertoast.showToast(msg: 'Enter user id & role', toastLength: Toast.LENGTH_SHORT);
      return;
    }
    setState(() => saving = true);
    try {
      await FirestoreService.addUser({
        'userId': id,
        'role': role,
        'password': 'default123', // default password to give
        'mustChange': true,
        'failed': 0,
        'locked': false,
      });
      Fluttertoast.showToast(msg: 'User added');
      Navigator.pop(context);
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e', toastLength: Toast.LENGTH_LONG);
    } finally {
      setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FloatingBox(
        child: Column(
          children: [
            TextField(controller: idCtrl, decoration: const InputDecoration(hintText: 'User ID')),
            const SizedBox(height: 8),
            TextField(controller: roleCtrl, decoration: const InputDecoration(hintText: 'role e.g. staff / hod / principal')),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: saving ? null : saveUser, child: saving ? CircularProgressIndicator() : const Text('Add')),
          ],
        ),
      ),
    );
  }
}
