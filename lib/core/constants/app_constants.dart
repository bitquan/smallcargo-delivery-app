import 'package:flutter/material.dart';

class AppConstants {
  // App Information
  static const String appName = 'Small Cargo';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Efficient cargo tracking and delivery management';
  
  // Navigation
  static const String homeRoute = '/home';
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String profileRoute = '/profile';
  static const String ordersRoute = '/orders';
  static const String trackingRoute = '/tracking';
  static const String mapsRoute = '/maps';
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);
  
  // Sizes
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double cardElevation = 4.0;
  
  // Map Settings
  static const double defaultMapZoom = 12.0;
  static const double maxMapZoom = 20.0;
  static const double minMapZoom = 3.0;
  
  // API Settings
  static const int requestTimeout = 30;
  static const int retryAttempts = 3;
  
  // Validation
  static const int minPasswordLength = 6;
  static const int maxNameLength = 50;
  static const int maxDescriptionLength = 500;
  
  // Colors
  static const Color primaryColor = Color(0xFFFFC107); // Amber/Yellow
  static const Color secondaryColor = Color(0xFF000000); // Black
  static const Color accentColor = Color(0xFFFFC107); // Yellow (removing teal)
  static const Color successColor = Color(0xFF00FF00); // Bright green
  static const Color errorColor = Color(0xFFFF0000); // Bright red
  static const Color warningColor = Color(0xFFFFC107); // Yellow
  
  // Status Colors
  static const Color pendingColor = Color(0xFFFFC107); // Yellow
  static const Color inProgressColor = Color(0xFFFFC107); // Yellow
  static const Color completedColor = Color(0xFF00FF00); // Bright green
  static const Color cancelledColor = Color(0xFFFF0000); // Bright red
  
  // Text Styles
  static const TextStyle titleStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Color(0xFFFFC107), // Yellow
  );
  
  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Color(0xFFFFC107), // Yellow
  );
  
  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16,
    color: Color(0xFFFFC107), // Yellow
  );
  
  static const TextStyle captionStyle = TextStyle(
    fontSize: 14,
    color: Color(0xFFFFC107), // Yellow
  );
}
