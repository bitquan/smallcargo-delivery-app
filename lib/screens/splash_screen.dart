import 'package:flutter/material.dart';
import '../core/design_system/app_design_system.dart';
import '../core/constants/app_constants.dart';
import '../widgets/animated_loading.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppDesignSystem.primaryGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 140,
                height: 140,
                decoration: AppDesignSystem.heroCardDecoration.copyWith(
                  border: Border.all(color: AppDesignSystem.primaryGold, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppDesignSystem.primaryGold.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.local_shipping,
                          size: 80,
                          color: AppDesignSystem.primaryGold,
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              
              // App Name
              Text(
                AppConstants.appName,
                style: AppDesignSystem.displayLarge.copyWith(
                  color: AppDesignSystem.primaryGold,
                  shadows: [
                    Shadow(
                      offset: const Offset(0, 2),
                      blurRadius: 8,
                      color: AppDesignSystem.backgroundDark.withValues(alpha: 0.7),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  AppConstants.appDescription,
                  style: AppDesignSystem.bodyLarge.copyWith(
                    color: AppDesignSystem.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 60),
              
              // Animated loading
              const AnimatedLoadingWidget(
                message: 'Loading...',
                size: 80,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
