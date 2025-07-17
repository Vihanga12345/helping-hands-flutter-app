import 'package:flutter/material.dart';
import '../../models/user_type.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';

class User1StartPage extends StatefulWidget {
  const User1StartPage({super.key});

  @override
  State<User1StartPage> createState() => _User1StartPageState();
}

class _User1StartPageState extends State<User1StartPage> {
  @override
  void initState() {
    super.initState();
    // Auto-navigate to next page after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        context.go('/intro1');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final logoSize = screenSize.width * 0.6; // 60% of screen width

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(0.50, 0.00),
            end: Alignment(0.50, 1.00),
            colors: AppColors.backgroundGradient,
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: screenSize.height -
                MediaQuery.of(context).padding.top -
                MediaQuery.of(context).padding.bottom,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Logo Section - Using PNG Image
                Container(
                  width: logoSize.clamp(200.0, 300.0), // Min 200, Max 300
                  height: logoSize.clamp(200.0, 300.0),
                  padding: const EdgeInsets.all(20),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),

                SizedBox(
                    height: screenSize.height * 0.04), // 4% of screen height

                // App Name
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Helping Hands',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.darkGreen,
                      fontSize: (screenSize.width * 0.1)
                          .clamp(24.0, 40.0), // Responsive font size
                      fontWeight: FontWeight.w700,
                      shadows: const [
                        Shadow(
                          offset: Offset(0, 4),
                          blurRadius: 4,
                          color: AppColors.shadowColor,
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                // Tagline
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: 40,
                    left: 24,
                    right: 24,
                  ),
                  child: Text(
                    'Together we grow',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.darkGreen,
                      fontSize: (screenSize.width * 0.05)
                          .clamp(16.0, 20.0), // Responsive font size
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
