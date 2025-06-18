import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';

class User5UserSelectionPage extends StatelessWidget {
  const User5UserSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                const SizedBox(height: 60),
                
                // Logo - Using PNG Image
                Container(
                  width: 120,
                  height: 120,
                  padding: const EdgeInsets.all(10),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // App Name
                const Text(
                  'Helping Hands',
                  style: TextStyle(
                    color: AppColors.darkGreen,
                    fontSize: 28,
                    
                    fontWeight: FontWeight.w700,
                  ),
                ),
                
                const SizedBox(height: 60),
                
                // Prompt Text
                const Text(
                  'Who are you?',
                  style: TextStyle(),
                ),
                
                const SizedBox(height: 40),
                
                // I'm a helpee Button
                _buildSelectionButton(
                  context,
                  text: "I'm a helpee",
                  onTap: () => context.go('/helpee-auth'),
                ),
                
                const SizedBox(height: 20),
                
                // I'm a helper Button
                _buildSelectionButton(
                  context,
                  text: "I'm a helper",
                  onTap: () => context.go('/helper-auth'),
                ),
                
                const Spacer(),
                
                // Information Button
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: TextButton(
                    onPressed: () {
                      // Navigate to information page (to be implemented)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Information page coming soon!'),
                        ),
                      );
                    },
                    child: const Text(
                      'Information',
                      style: TextStyle(
                        color: AppColors.darkGreen,
                        fontSize: 16,
                        
                        fontWeight: FontWeight.w400,
                        decoration: TextDecoration.underline,
                      ),
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
  
  Widget _buildSelectionButton(BuildContext context, {
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 80,
        decoration: ShapeDecoration(
          color: AppColors.lightGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          shadows: const [
            BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 4,
              offset: Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(),
          ),
        ),
      ),
    );
  }
} 
