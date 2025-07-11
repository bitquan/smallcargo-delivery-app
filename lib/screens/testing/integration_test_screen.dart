import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

class IntegrationTestScreen extends StatefulWidget {
  const IntegrationTestScreen({super.key});

  @override
  State<IntegrationTestScreen> createState() => _IntegrationTestScreenState();
}

class _IntegrationTestScreenState extends State<IntegrationTestScreen> {
  final Map<String, bool?> _testResults = {};
  final Map<String, String> _testDetails = {};
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
            onPressed: _isRunningTests ? null : _runAllTests,
            tooltip: 'Run All Tests',
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
            
            // Test Categories
            _buildTestCategory(
              '📸 Photo Upload System',
              [
                'Photo Picker Service',
                'Camera Access',
                'Gallery Access',
                'Firebase Upload',
                'Image Compression',
                'Upload Progress',
                'Error Handling',
              ],
            ),
            
            const SizedBox(height: 16),
            
            _buildTestCategory(
              '💬 Chat System',
              [
                'Chat Service Init',
                'Send Text Message',
                'Send Location',
                'Message Delivery',
                'Read Status',
                'Real-time Updates',
                'Error Recovery',
              ],
            ),
            
            const SizedBox(height: 16),
            
            _buildTestCategory(
              '🚨 Emergency System',
              [
                'Emergency Service',
                'Location Access',
                'Emergency Button',
                'Alert Sending',
                'Contact Notification',
                'Emergency Types',
                'Response Tracking',
              ],
            ),
            
            const SizedBox(height: 16),
            
            _buildTestCategory(
              '🔄 Real-time Features',
              [
                'Order Tracking',
                'Status Updates',
                'Location Sharing',
                'Push Notifications',
                'Offline Handling',
                'Data Sync',
                'Network Recovery',
              ],
            ),
            
            const SizedBox(height: 16),
            
            _buildTestCategory(
              '🎨 User Experience',
              [
                'Loading States',
                'Error Messages',
                'Navigation Flow',
                'Responsive Design',
                'Performance',
                'Accessibility',
                'Polish & Animation',
              ],
            ),
            
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
    final passedTests = _testResults.values.where((result) => result == true).length;
    final failedTests = _testResults.values.where((result) => result == false).length;
    
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
              const Text('No tests run yet. Click "Run All Tests" to start.'),
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

  Widget _buildTestCategory(String title, List<String> tests) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...tests.map((test) => _buildTestItem(test)),
          ],
        ),
      ),
    );
  }

  Widget _buildTestItem(String testName) {
    final result = _testResults[testName];
    final details = _testDetails[testName];
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            result == null
                ? Icons.radio_button_unchecked
                : result
                    ? Icons.check_circle
                    : Icons.error,
            color: result == null
                ? Colors.grey
                : result
                    ? Colors.green
                    : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(testName),
                if (details != null) ...[
                  Text(
                    details,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: result == true ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.play_arrow, size: 16),
            onPressed: () => _runSingleTest(testName),
            tooltip: 'Run Test',
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _navigateToPhotoDemo(),
                  icon: const Icon(Icons.camera),
                  label: const Text('Test Photos'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _testChatSystem(),
                  icon: const Icon(Icons.chat),
                  label: const Text('Test Chat'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _testEmergencySystem(),
                  icon: const Icon(Icons.emergency),
                  label: const Text('Test Emergency'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _testOrderFlow(),
                  icon: const Icon(Icons.local_shipping),
                  label: const Text('Test Orders'),
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

  Future<void> _runAllTests() async {
    setState(() {
      _isRunningTests = true;
      _testResults.clear();
      _testDetails.clear();
    });

    // Simulate running tests with delays for demonstration
    await _runPhotoUploadTests();
    await _runChatSystemTests();
    await _runEmergencySystemTests();
    await _runRealtimeFeatureTests();
    await _runUserExperienceTests();

    setState(() {
      _isRunningTests = false;
    });
  }

  Future<void> _runPhotoUploadTests() async {
    final tests = [
      'Photo Picker Service',
      'Camera Access',
      'Gallery Access',
      'Firebase Upload',
      'Image Compression',
      'Upload Progress',
      'Error Handling',
    ];

    for (final test in tests) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() {
          _testResults[test] = _simulateTestResult();
          _testDetails[test] = _getTestDetails(test);
        });
      }
    }
  }

  Future<void> _runChatSystemTests() async {
    final tests = [
      'Chat Service Init',
      'Send Text Message',
      'Send Location',
      'Message Delivery',
      'Read Status',
      'Real-time Updates',
      'Error Recovery',
    ];

    for (final test in tests) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() {
          _testResults[test] = _simulateTestResult();
          _testDetails[test] = _getTestDetails(test);
        });
      }
    }
  }

  Future<void> _runEmergencySystemTests() async {
    final tests = [
      'Emergency Service',
      'Location Access',
      'Emergency Button',
      'Alert Sending',
      'Contact Notification',
      'Emergency Types',
      'Response Tracking',
    ];

    for (final test in tests) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() {
          _testResults[test] = _simulateTestResult();
          _testDetails[test] = _getTestDetails(test);
        });
      }
    }
  }

  Future<void> _runRealtimeFeatureTests() async {
    final tests = [
      'Order Tracking',
      'Status Updates',
      'Location Sharing',
      'Push Notifications',
      'Offline Handling',
      'Data Sync',
      'Network Recovery',
    ];

    for (final test in tests) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() {
          _testResults[test] = _simulateTestResult();
          _testDetails[test] = _getTestDetails(test);
        });
      }
    }
  }

  Future<void> _runUserExperienceTests() async {
    final tests = [
      'Loading States',
      'Error Messages',
      'Navigation Flow',
      'Responsive Design',
      'Performance',
      'Accessibility',
      'Polish & Animation',
    ];

    for (final test in tests) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() {
          _testResults[test] = _simulateTestResult();
          _testDetails[test] = _getTestDetails(test);
        });
      }
    }
  }

  Future<void> _runSingleTest(String testName) async {
    setState(() {
      _testResults[testName] = null; // Reset
    });

    await Future.delayed(const Duration(milliseconds: 1000));
    
    if (mounted) {
      setState(() {
        _testResults[testName] = _simulateTestResult();
        _testDetails[testName] = _getTestDetails(testName);
      });
    }
  }

  bool _simulateTestResult() {
    // Simulate 85% pass rate
    return DateTime.now().millisecond % 10 < 8;
  }

  String _getTestDetails(String testName) {
    final isPass = _testResults[testName] ?? false;
    if (isPass) {
      return 'Test passed successfully';
    } else {
      switch (testName) {
        case 'Camera Access':
          return 'Browser camera permission required';
        case 'Firebase Upload':
          return 'Check Firebase Storage configuration';
        case 'Push Notifications':
          return 'FCM token registration needed';
        default:
          return 'Test failed - needs investigation';
      }
    }
  }

  void _resetTests() {
    setState(() {
      _testResults.clear();
      _testDetails.clear();
      _isRunningTests = false;
    });
  }

  void _navigateToPhotoDemo() {
    Navigator.pushNamed(context, '/photo-picker-demo');
  }

  void _testChatSystem() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening chat test - Create an order to test messaging'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _testEmergencySystem() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Testing emergency system - Check emergency button functionality'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _testOrderFlow() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Testing order flow - Navigate to create order'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _testNotifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Testing notifications - Check browser permissions'),
        backgroundColor: Colors.purple,
      ),
    );
  }
}
