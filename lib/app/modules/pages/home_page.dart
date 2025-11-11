import 'package:flutter/material.dart';
import 'package:get/get.dart';


// correct relative path: from app/modules/pages -> up to lib/, then into presentation/...
import '../../../presentation/home_screen/home_screen.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // drop `const` unless HomeScreen has a const ctor
    return HomeScreen();
  }
}
