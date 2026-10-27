import 'package:flutter/material.dart';

/// Re-usable scaffold with ATRIA background + big rounded floating panel.
///
/// Used by:
///  - EmailCollectionScreen
///  - PublicHomeScreen
///  - Login / dashboards (if you use it there)
class BrandedScaffold extends StatelessWidget {
  final String title;
  final Widget child;

  const BrandedScaffold({
    Key? key,
    required this.title,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
              color: Colors.white.withOpacity(0.86),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 🔹 Make the floating box occupy ~90% of the screen width
                //    but keep a good max width so it still looks nice.
                final double panelWidth = (constraints.maxWidth * 0.9)
                    .clamp(360.0, 1100.0);

                // Almost full height, with a little margin top/bottom
                final double panelHeight =
                    (constraints.maxHeight - 32).clamp(300.0, constraints.maxHeight);

                return Center(
                  child: SizedBox(
                    width: panelWidth,
                    height: panelHeight,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.96),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Title centred like your screenshots
                            Center(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // The actual page content
                            Expanded(
                              child: child,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}