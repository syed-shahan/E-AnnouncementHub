import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

class EmailScreen extends StatefulWidget {
  const EmailScreen({super.key});

  @override
  State<EmailScreen> createState() => _EmailScreenState();
}

class _EmailScreenState extends State<EmailScreen> {
  final TextEditingController emailCtrl = TextEditingController();
  bool loading = false;

  submitEmail() async {
    if (emailCtrl.text.isEmpty) {
      Fluttertoast.showToast(msg: "Enter email");
      return;
    }
    setState(() => loading = true);

    try {
      await FirebaseFirestore.instance.collection("pending_emails").doc(emailCtrl.text).set({
        "email": emailCtrl.text,
        "timestamp": DateTime.now(),
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool("email_submitted", true);

      Fluttertoast.showToast(msg: "Email submitted");
      Navigator.pushReplacementNamed(context, '/announcements');
    } catch (e) {
      Fluttertoast.showToast(msg: "Error");
    }
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return _bg(
      child: Center(
        child: _card(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset("assets/logo.png", height: 90),
              const SizedBox(height: 20),
              _field(emailCtrl, "Enter Email"),
              const SizedBox(height: 10),
              _btn("Continue", submitEmail, loading),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- UI helpers (LOCKED forever) ----------
  Widget _bg({required Widget child}) => Container(
    decoration: const BoxDecoration(
      image: DecorationImage(image: AssetImage("assets/college_bg.jpeg"), fit: BoxFit.cover),
    ),
    child: child,
  );

  Widget _card(Widget child) => Container(
    margin: const EdgeInsets.all(28),
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(.85),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black26)],
    ),
    child: child,
  );

  Widget _field(TextEditingController c, String h) => TextField(
    controller: c,
    decoration: InputDecoration(border: OutlineInputBorder(), hintText: h),
  );

  Widget _btn(String t, Function f, bool l) => ElevatedButton(
    onPressed: l ? null : () => f(),
    child: l ? CircularProgressIndicator() : Text(t),
  );
}
