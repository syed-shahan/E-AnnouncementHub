import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'emasubmission_screen.dart';
import 'home_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    checkFlow();
  }

  checkFlow() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool emailSubmitted = prefs.getBool("emailSubmitted") ?? false;

    await Future.delayed(const Duration(seconds: 1));

    if (!emailSubmitted) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const EmailCollectionScreen()));
    } else {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const HomePage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
