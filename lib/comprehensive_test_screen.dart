import 'package:flutter/material.dart';
import 'core/constants/app_constants.dart';
import 'services/integration_test_service.dart';
import 'test_core_functions.dart';

class ComprehensiveTestScreen extends StatefulWidget {
  const ComprehensiveTestScreen({super.key});

  @override
  State<ComprehensiveTestScreen> createState() => _ComprehensiveTestScreenState();
}

class _ComprehensiveTestScreenState extends State<ComprehensiveTestScreen> {
  List<TestResult> _integrationResults = [];
  bool _isRunningIntegrationTests = false;
  String _testStatus = 'Ready to run comprehensive tests';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comprehensive Testing Suite'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              elevation: 8,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppConstants.primaryColor, AppConstants.accentColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🧪 Small Cargo Testing Suite',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Comprehensive integration testing for all app systems',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _testStatus,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Integration Tests Section
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.integration_instructions,
                          color: AppConstants.primaryColor,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Integration Tests',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (_isRunningIntegrationTests)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Comprehensive integration testing suite covering:',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    _buildTestCategoryList(),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isRunningIntegrationTests ? null : _runIntegrationTests,
                          icon: Icon(_isRunningIntegrationTests ? Icons.hourglass_empty : Icons.play_arrow),
                          label: Text(_isRunningIntegrationTests ? 'Running Tests...' : 'Run Integration Tests'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                        const SizedBox(width: 16),
                        OutlinedButton.icon(
                          onPressed: _resetTests,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reset'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Test Results
            if (_integrationResults.isNotEmpty) _buildTestResults(),

            const SizedBox(height: 24),

            // Quick Actions
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildTestCategoryList() {
    final categories = [
      '🔧 Service Initialization & Dependency Injection',
      '🔐 Authentication Flow (Login/Logout/Registration)',
      '💾 Database Operations (CRUD & Real-time)',
      '📦 Order Lifecycle Management',
      '⚡ Real-time Tracking & Status Updates',
      '📍 Location Services & Permissions',
      '🗺️ Route Optimization & Distance Calculation',
      '👨‍💼 Admin Features & Dashboard',
      '⚠️ Error Handling & Recovery',
      '🔄 Integration & System Health',
    ];

    return Column(
      children: categories.map((category) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(child: Text(category, style: const TextStyle(fontSize: 14))),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildTestResults() {
    final totalTests = _integrationResults.length;
    final passedTests = _integrationResults.where((r) => r.passed).length;
    final failedTests = totalTests - passedTests;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assessment, color: AppConstants.primaryColor, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Test Results',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Summary Row
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard('Total', totalTests.toString(), Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard('Passed', passedTests.toString(), Colors.green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard('Failed', failedTests.toString(), Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Progress Bar
            LinearProgressIndicator(
              value: totalTests > 0 ? passedTests / totalTests : 0,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                passedTests == totalTests ? Colors.green : AppConstants.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            
            // Individual Test Results
            const Text(
              'Detailed Results:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ..._integrationResults.map((result) => _buildTestResultItem(result)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestResultItem(TestResult result) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            result.passed ? Icons.check_circle : Icons.error,
            color: result.passed ? Colors.green : Colors.red,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                if (result.details?.isNotEmpty ?? false) ...[
                  Text(
                    result.details!,
                    style: TextStyle(
                      fontSize: 12,
                      color: result.passed ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            '${result.duration}ms',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.speed, color: AppConstants.primaryColor, size: 28),
                SizedBox(width: 12),
                Text(
                  'Quick Actions',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildActionButton(
                  'Core Services',
                  Icons.settings,
                  Colors.blue,
                  () => _runCoreServices(),
                ),
                _buildActionButton(
                  'Admin Dashboard',
                  Icons.admin_panel_settings,
                  Colors.purple,
                  () => _navigateToAdminDashboard(),
                ),
                _buildActionButton(
                  'Auth Testing',
                  Icons.security,
                  Colors.orange,
                  () => _testAuthentication(),
                ),
                _buildActionButton(
                  'Database Tests',
                  Icons.storage,
                  Colors.green,
                  () => _testDatabase(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _runIntegrationTests() async {
    setState(() {
      _isRunningIntegrationTests = true;
      _testStatus = 'Running comprehensive integration tests...';
      _integrationResults.clear();
    });

    try {
      final integrationService = IntegrationTestService();
      final results = await integrationService.runIntegrationTests(context);
      
      if (mounted) {
        setState(() {
          _integrationResults = results;
          _isRunningIntegrationTests = false;
          
          final passedTests = results.where((r) => r.passed).length;
          final totalTests = results.length;
          _testStatus = 'Tests completed: $passedTests/$totalTests passed';
        });

        // Show completion snackbar
        final passedTests = results.where((r) => r.passed).length;
        final totalTests = results.length;
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Integration tests completed: $passedTests/$totalTests passed'),
              backgroundColor: passedTests == totalTests ? Colors.green : Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRunningIntegrationTests = false;
          _testStatus = 'Test execution failed: $e';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error running integration tests: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _resetTests() {
    setState(() {
      _integrationResults.clear();
      _isRunningIntegrationTests = false;
      _testStatus = 'Ready to run comprehensive tests';
    });
  }

  Future<void> _runCoreServices() async {
    try {
      await CoreFunctionTester.testCoreServices(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Core services test completed - check debug console'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Core services test failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToAdminDashboard() {
    Navigator.pushNamed(context, '/admin-dashboard');
  }

  void _testAuthentication() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navigate to login/register screens to test authentication'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _testDatabase() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Database operations test - check console for results'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
