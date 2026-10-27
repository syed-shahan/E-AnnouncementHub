import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddStaffScreen extends StatefulWidget {
  const AddStaffScreen({super.key});

  @override
  State<AddStaffScreen> createState() => _AddStaffScreenState();
}

class _AddStaffScreenState extends State<AddStaffScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  String role = "staff";

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox.expand(child: Image.asset("assets/college_bg.jpeg", fit: BoxFit.cover)),

        Scaffold(
          backgroundColor: Colors.black.withOpacity(0.40),

          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text("Add Staff / HOD", style: TextStyle(fontWeight: FontWeight.bold)),
            centerTitle: true,
          ),

          body: Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),

              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _textField(emailCtrl, "Email"),
                  const SizedBox(height: 12),
                  _textField(passCtrl, "Password"),
                  const SizedBox(height: 12),

                  DropdownButton<String>(
                    dropdownColor: Colors.black87,
                    value: role,
                    items: const [
                      DropdownMenuItem(value: "staff", child: Text("Staff")),
                      DropdownMenuItem(value: "hod", child: Text("HOD")),
                      DropdownMenuItem(value: "principal", child: Text("Principal")),
                    ],
                    onChanged: (v) => setState(() => role = v!),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text("Add User"),
                  )
                ],
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _textField(TextEditingController c, String text) {
    return TextField(
      controller: c,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: text,
        labelStyle: const TextStyle(color: Colors.white),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white.withOpacity(0.6)),
        ),
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
      ),
    );
  }

  Future<void> _save() async {
    await FirebaseFirestore.instance.collection("admin_users").add({
      "email": emailCtrl.text,
      "password": passCtrl.text,
      "role": role,
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("User added successfully"),
    ));

    Navigator.pop(context);
  }
}
