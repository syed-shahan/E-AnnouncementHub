import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageUsersScreen extends StatefulWidget {
  @override
  _ManageUsersScreenState createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  TextEditingController email = TextEditingController();
  TextEditingController role = TextEditingController();
  TextEditingController password = TextEditingController();

  addUser() async {
    if (email.text.isEmpty || role.text.isEmpty || password.text.isEmpty) return;

    await FirebaseFirestore.instance.collection("admin_users").add({
      "email": email.text.trim(),
      "role": role.text.trim(),
      "password": password.text.trim(), // Admin will create and share
    });

    email.clear(); role.clear(); password.clear();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("User Added")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Manage Users"), backgroundColor: Colors.black),
      backgroundColor: Color(0xff111827),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(children: [
          field(email, "Enter staff/HOD email"),
          field(role, "Role (staff/hod/principal)"),
          field(password, "Create password"),

          ElevatedButton(onPressed: addUser, child: Text("Add User"))
        ]),
      ),
    );
  }

  Widget field(ctrl, text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: text,
          labelStyle: TextStyle(color: Colors.white60),
        ),
      ),
    );
  }
}
