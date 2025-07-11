import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/themes/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'services/route_optimization_service.dart';
import 'services/push_notification_service.dart';
import 'services/photo_upload_service.dart';
import 'services/photo_picker_service.dart';
import 'services/chat_service.dart';
import 'services/emergency_service.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/testing/integration_test_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'comprehensive_test_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Push Notifications
  await PushNotificationService().initialize();
  
  runApp(const SmallCargoApp());
}

class SmallCargoApp extends StatelessWidget {
  const SmallCargoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<DatabaseService>(create: (_) => DatabaseService()),
        Provider<RouteOptimizationService>(create: (_) => RouteOptimizationService()),
        Provider<PushNotificationService>(create: (_) => PushNotificationService()),
        Provider<PhotoUploadService>(create: (_) => PhotoUploadService()),
        Provider<PhotoPickerService>(create: (_) => PhotoPickerService()),
        Provider<ChatService>(create: (_) => ChatService()),
        Provider<EmergencyService>(create: (_) => EmergencyService()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        theme: AppTheme.lightTheme,
        themeMode: ThemeMode.light, // Force light theme (which is our black theme)
        debugShowCheckedModeBanner: false,
        home: const AuthWrapper(),
        routes: {
          AppConstants.homeRoute: (context) => const HomeScreen(),
          AppConstants.loginRoute: (context) => const LoginScreen(),
          '/integration-test': (context) => const IntegrationTestScreen(),
          '/admin-dashboard': (context) => const AdminDashboardScreen(),
          '/comprehensive-test': (context) => const ComprehensiveTestScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        
        // Check for authentication error states
        if (snapshot.hasError) {
          return const LoginScreen();
        }
        
        if (snapshot.hasData && snapshot.data != null) {
          return const HomeScreen();
        }
        
        // User is signed out - show login screen
        return const LoginScreen();
      },
    );
  }
}
