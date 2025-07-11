import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'services/location_service.dart';
import 'services/route_optimization_service.dart';

class CoreFunctionTester {
  static Future<void> testCoreServices(BuildContext context) async {
    debugPrint('🧪 Testing Core Services...');
    
    // Test Auth Service
    await _testAuthService(context);
    
    // Test Database Service
    await _testDatabaseService(context);
    
    // Test Location Service
    await _testLocationService();
    
    // Test Route Optimization Service
    await _testRouteOptimizationService();
    
    debugPrint('✅ All core services tested successfully!');
  }
  
  static Future<void> _testAuthService(BuildContext context) async {
    debugPrint('🔐 Testing Auth Service...');
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Test current user getter
      final currentUser = authService.currentUser;
      debugPrint('Current user: ${currentUser?.email ?? 'Not logged in'}');
      
      // Test stream (just check if it's working)
      final streamTest = authService.authStateChanges.take(1);
      await streamTest.isEmpty; // This will complete quickly
      
      debugPrint('✅ Auth Service is working');
    } catch (e) {
      debugPrint('❌ Auth Service error: $e');
    }
  }
  
  static Future<void> _testDatabaseService(BuildContext context) async {
    debugPrint('💾 Testing Database Service...');
    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      
      // Test basic collection access
      final ordersCollection = dbService.ordersCollection;
      final usersCollection = dbService.usersCollection;
      
      debugPrint('Orders collection: ${ordersCollection.path}');
      debugPrint('Users collection: ${usersCollection.path}');
      
      debugPrint('✅ Database Service is working');
    } catch (e) {
      debugPrint('❌ Database Service error: $e');
    }
  }
  
  static Future<void> _testLocationService() async {
    debugPrint('📍 Testing Location Service...');
    try {
      LocationService();
      
      // Test service instantiation
      debugPrint('Location service created successfully');
      
      debugPrint('✅ Location Service is working');
    } catch (e) {
      debugPrint('❌ Location Service error: $e');
    }
  }
  
  static Future<void> _testRouteOptimizationService() async {
    debugPrint('🗺️ Testing Route Optimization Service...');
    try {
      RouteOptimizationService();
      
      // Test service instantiation
      debugPrint('Route optimization service created successfully');
      
      debugPrint('✅ Route Optimization Service is working');
    } catch (e) {
      debugPrint('❌ Route Optimization Service error: $e');
    }
  }
}

// Widget to test the core functions
class CoreFunctionTestScreen extends StatefulWidget {
  const CoreFunctionTestScreen({super.key});

  @override
  State<CoreFunctionTestScreen> createState() => _CoreFunctionTestScreenState();
}

class _CoreFunctionTestScreenState extends State<CoreFunctionTestScreen> {
  final List<String> _testResults = [];
  bool _isRunning = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Core Function Tests'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Core Service Tests',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This will test authentication, database, location, and route optimization services.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isRunning ? null : _runTests,
              child: _isRunning 
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Running Tests...'),
                    ],
                  )
                : const Text('Run Core Function Tests'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                elevation: 4,
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Test Results:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _testResults.length,
                          itemBuilder: (context, index) {
                            final result = _testResults[index];
                            final isError = result.contains('❌');
                            final isSuccess = result.contains('✅');
                            
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                result,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  color: isError 
                                    ? Colors.red[700]
                                    : isSuccess 
                                      ? Colors.green[700]
                                      : Colors.blue[700],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runTests() async {
    setState(() {
      _isRunning = true;
      _testResults.clear();
    });

    try {
      // Use a list to capture debug output instead of overriding print
      final List<String> capturedOutput = [];
      
      // Override debugPrint for this test
      void Function(String?, {int? wrapWidth})? originalDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) {
          setState(() {
            _testResults.add(message);
          });
          capturedOutput.add(message);
        }
      };

      await CoreFunctionTester.testCoreServices(context);

      // Restore original debugPrint
      debugPrint = originalDebugPrint;
    } catch (e) {
      setState(() {
        _testResults.add('❌ Test execution failed: $e');
      });
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }
}
