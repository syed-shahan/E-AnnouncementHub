import 'package:flutter/material.dart';

class FloatingBox extends StatelessWidget {
  final Widget child;
  final double width;
  final double padding;
  const FloatingBox({
    super.key,
    required this.child,
    this.width = 360,
    this.padding = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // dimmed background visible
        Positioned.fill(
          child: Image.asset(
            'assets/college_bg.jpeg',
            fit: BoxFit.cover,
            color: Colors.black.withOpacity(0.25),
            colorBlendMode: BlendMode.darken,
          ),
        ),
        Center(
          child: Container(
            width: width,
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 14,
                    offset: Offset(0, 8))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo on top inside the floating box
                Image.asset('assets/logo.png',
                    width: double.infinity, height: 60, fit: BoxFit.contain),
                const SizedBox(height: 12),
                child,
              ],
            ),
          ),
        ),
      ],
    );
  }
}
