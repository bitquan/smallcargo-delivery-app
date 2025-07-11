import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../services/integration_test_service.dart';

class IntegrationTestScreen extends StatefulWidget {
  const IntegrationTestScreen({super.key});

  @override
  State<IntegrationTestScreen> createState() => _IntegrationTestScreenState();
}

class _IntegrationTestScreenState extends State<IntegrationTestScreen> {
  final IntegrationTestService _testService = IntegrationTestService();
  List<TestResult> _testResults = [];
  bool _isRunningTests = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Integration Testing Dashboard'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: _isRunningTests ? null : _runIntegrationTests,
            tooltip: 'Run Integration Tests',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetTests,
            tooltip: 'Reset Tests',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Test Summary Card
            _buildTestSummaryCard(),
            
            const SizedBox(height: 20),
            
            // Instructions
            _buildInstructionsCard(),
            
            const SizedBox(height: 20),
            
            // Test Results
            if (_testResults.isNotEmpty) _buildTestResultsCard(),
            
            const SizedBox(height: 20),
            
            // Manual Test Actions
            _buildManualTestActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildTestSummaryCard() {
    final totalTests = _testResults.length;
    final passedTests = _testResults.where((result) => result.passed).length;
    final failedTests = totalTests - passedTests;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test Summary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (totalTests > 0) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryItem(
                      'Total Tests',
                      totalTests.toString(),
                      Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _buildSummaryItem(
                      'Passed',
                      passedTests.toString(),
                      Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildSummaryItem(
                      'Failed',
                      failedTests.toString(),
                      Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: totalTests > 0 ? passedTests / totalTests : 0,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  passedTests == totalTests ? Colors.green : AppConstants.primaryColor,
                ),
              ),
            ] else ...[
              const Text('No tests run yet. Click "Run Integration Tests" to start.'),
            ],
            if (_isRunningTests) ...[
              const SizedBox(height: 12),
              const Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Running tests...'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
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
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildInstructionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📋 Integration Testing Instructions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            const Text(
              'This comprehensive integration testing suite will verify all core systems work together properly:',
            ),
            const SizedBox(height: 8),
            const Text('• Service Initialization & Dependency Injection'),
            const Text('• Authentication Flow (Login/Logout/Registration)'),
            const Text('• Database Operations (CRUD & Real-time)'),
            const Text('• Order Lifecycle Management'),
            const Text('• Real-time Tracking & Status Updates'),
            const Text('• Location Services & Permissions'),
            const Text('• Route Optimization & Distance Calculation'),
            const Text('• Distance Calculation Service'),
            const Text('• Admin Features & Dashboard'),
            const Text('• Error Handling & Recovery'),
            const SizedBox(height: 12),
            const Text(
              'Click "Run Integration Tests" to start the comprehensive test suite.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestResultsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test Results',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ..._testResults.map((result) => _buildTestResultItem(result)),
          ],
        ),
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
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (result.details?.isNotEmpty ?? false) ...[
                  Text(
                    result.details!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: result.passed ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualTestActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🧪 Manual Test Actions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            const Text(
              'After integration tests pass, use these buttons to manually test specific features:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _navigateToAdminDashboard(),
                  icon: const Icon(Icons.admin_panel_settings),
                  label: const Text('Test Admin Dashboard'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _testOrderFlow(),
                  icon: const Icon(Icons.local_shipping),
                  label: const Text('Test Order Flow'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _testAuthentication(),
                  icon: const Icon(Icons.login),
                  label: const Text('Test Authentication'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _testLocation(),
                  icon: const Icon(Icons.location_on),
                  label: const Text('Test Location Services'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _testNotifications(),
                  icon: const Icon(Icons.notifications),
                  label: const Text('Test Notifications'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runIntegrationTests() async {
    setState(() {
      _isRunningTests = true;
      _testResults.clear();
    });

    try {
      final results = await _testService.runIntegrationTests(context);
      
      if (mounted) {
        setState(() {
          _testResults = results;
          _isRunningTests = false;
        });
        
        final passedTests = results.where((r) => r.passed).length;
        final totalTests = results.length;
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Integration tests completed: $passedTests/$totalTests passed',
              ),
              backgroundColor: passedTests == totalTests ? Colors.green : Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRunningTests = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error running tests: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _resetTests() {
    setState(() {
      _testResults.clear();
      _isRunningTests = false;
    });
  }

  void _navigateToAdminDashboard() {
    Navigator.pushNamed(context, '/admin-dashboard');
  }

  void _testOrderFlow() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navigate to Customer Dashboard to test order creation flow'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _testAuthentication() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navigate to Login/Register screens to test authentication'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _testLocation() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Check browser location permission in address bar'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _testNotifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Check browser notification permission in address bar'),
        backgroundColor: Colors.purple,
      ),
    );
  }
}
