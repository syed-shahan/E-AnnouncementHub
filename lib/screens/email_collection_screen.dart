import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmailCollectionScreen extends StatefulWidget {
  const EmailCollectionScreen({super.key});

  @override
  State<EmailCollectionScreen> createState() => _EmailCollectionScreenState();
}

class _EmailCollectionScreenState extends State<EmailCollectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final email = _emailController.text.trim();

    try {
      // Save locally so we don't show this screen again on this device
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasCollectedEmail', true);
      await prefs.setString('collectedEmail', email);

      // Firestore is optional – if anything goes wrong, we just log and continue.
      try {
        await FirebaseFirestore.instance.collection('collectedEmails').add({
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e, st) {
        debugPrint('Error saving collected email to Firestore (ignored): $e\n$st');
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e, st) {
      // Even if something unexpected happens, don't get stuck on this screen.
      debugPrint('Email submit error: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong, continuing to announcements…'),
          ),
        );
        Navigator.pushReplacementNamed(context, '/home');
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Slightly limit card width on huge screens so it doesn’t stretch too much.
    final double maxCardWidth = size.width < 600 ? size.width * 0.9 : 420;

    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/bg.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // Light overlay
          Positioned.fill(
            child: Container(
              color: Colors.white.withOpacity(0.88),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: maxCardWidth,
                    // make sure it feels “full height” on tall screens
                    minHeight: size.height * 0.45,
                  ),
                  child: Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Logo
                            Image.asset(
                              'assets/logo.png',
                              height: 80,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'Enter your email once on this device.\n'
                              'From next time you will be taken directly\n'
                              'to the announcements.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                final text = value?.trim() ?? '';
                                if (text.isEmpty) {
                                  return 'Email is required';
                                }
                                if (!text.contains('@') || !text.contains('.')) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _saving ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(0, 46),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                child: _saving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Continue'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}