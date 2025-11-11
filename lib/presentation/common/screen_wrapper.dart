import 'package:flutter/material.dart';
import '../../ui/visuals/brand_background.dart';

// Bottom NavigationBar height is ~80 on Material3. Add a little buffer.
const double kBottomNavVisualHeight = 80.0;
const double kPageSide = 20.0;
const double kPageTop = 20.0;
const double kGap = 16.0;

/// For non-scrolling pages (Home, Record)
class FixedScreen extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget child;

  const FixedScreen({super.key, this.appBar, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: appBar,
      body: Stack(
        children: [
          const BrandGradientBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                kPageSide, kPageTop, kPageSide, kGap,
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// For scrolling pages (Library, Settings)
class ScrollScreen extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final List<Widget> children;

  const ScrollScreen({super.key, this.appBar, required this.children});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: appBar,
      body: Stack(
        children: [
          const BrandGradientBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                kPageSide, kPageTop, kPageSide, kGap,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
