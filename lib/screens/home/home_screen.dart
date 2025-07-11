import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/design_system/app_design_system.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../models/order.dart' as order_model;
import '../../models/user.dart';
import '../orders/create_order_screen.dart';
import '../tracking/tracking_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../driver/driver_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: Provider.of<AuthService>(context, listen: false).authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppDesignSystem.backgroundDark,
            body: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppDesignSystem.primaryGold),
              ),
            ),
          );
        }
        
        final user = snapshot.data;
        
        // Driver gets a different dashboard
        if (user?.role == UserRole.driver) {
          return const DriverDashboardScreen();
        }
        
        // Admin gets a different dashboard
        if (user?.role == UserRole.admin) {
          return const AdminDashboardScreen();
        }
        
        final List<Widget> screens = [
          DashboardTab(user: user),
          OrdersTab(onNavigateToTracking: () {
            setState(() {
              _currentIndex = 2;
            });
          }),
          const TrackingScreen(),
          const ProfileTab(),
        ];

        return Scaffold(
          backgroundColor: AppDesignSystem.backgroundDark,
          body: screens[_currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppDesignSystem.backgroundCard,
            selectedItemColor: AppDesignSystem.primaryGold,
            unselectedItemColor: AppDesignSystem.textMuted,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.inventory),
                label: 'Orders',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.track_changes),
                label: 'Tracking',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }
}

class DashboardTab extends StatelessWidget {
  final User? user;
  
  const DashboardTab({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundDark,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with logo and profile
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppDesignSystem.primaryGold,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.local_shipping,
                                  color: AppDesignSystem.backgroundDark,
                                  size: 24,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Small Cargo',
                          style: AppDesignSystem.headlineMedium.copyWith(
                            color: AppDesignSystem.primaryGold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined, color: AppDesignSystem.primaryGold),
                          onPressed: () {},
                        ),
                        GestureDetector(
                          onTap: () async {
                            final authService = Provider.of<AuthService>(context, listen: false);
                            await authService.signOut();
                          },
                          child: CircleAvatar(
                            backgroundColor: AppDesignSystem.accentBlue,
                            child: Text(
                              user?.name.substring(0, 1).toUpperCase() ?? 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 30),
                
                // Welcome card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppDesignSystem.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppDesignSystem.primaryGold.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, ${user?.name ?? 'User'}!',
                        style: AppDesignSystem.headlineMedium.copyWith(
                          color: AppDesignSystem.backgroundDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Reliable and affordable logistics solutions for all your shipping needs.',
                        style: AppDesignSystem.bodyLarge.copyWith(
                          color: AppDesignSystem.backgroundDark.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Quick Actions
                Text(
                  'Quick Actions',
                  style: AppDesignSystem.headlineSmall.copyWith(
                    color: AppDesignSystem.primaryGold,
                  ),
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionCard(
                        context,
                        icon: Icons.add_box,
                        title: 'Ship Now',
                        subtitle: 'Create new order',
                        color: AppDesignSystem.primaryGold,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CreateOrderScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildQuickActionCard(
                        context,
                        icon: Icons.track_changes,
                        title: 'Track',
                        subtitle: 'Follow your package',
                        color: AppDesignSystem.accentBlue,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TrackingScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionCard(
                        context,
                        icon: Icons.history,
                        title: 'History',
                        subtitle: 'View past orders',
                        color: AppDesignSystem.accentPurple,
                        onTap: () {
                          // Navigate to orders tab
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildQuickActionCard(
                        context,
                        icon: Icons.support_agent,
                        title: 'Support',
                        subtitle: 'Get help',
                        color: AppDesignSystem.accentOrange,
                        onTap: () {
                          // Navigate to support
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 30),
                
                // Admin Row (only for admins)
                if (user?.role == UserRole.admin) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickActionCard(
                          context,
                          icon: Icons.admin_panel_settings,
                          title: 'Admin Panel',
                          subtitle: 'Admin dashboard',
                          color: AppDesignSystem.textMuted,
                          onTap: () {
                            Navigator.pushNamed(context, '/admin-dashboard');
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(), // Empty space
                      ),
                    ],
                  ),
                ],
                
                const SizedBox(height: 30),
                
                // Recent Orders
                Text(
                  'Recent Orders',
                  style: AppDesignSystem.headlineSmall.copyWith(
                    color: AppDesignSystem.primaryGold,
                  ),
                ),
                const SizedBox(height: 16),
                
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppDesignSystem.backgroundCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppDesignSystem.primaryGold, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: AppDesignSystem.primaryGold.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: StreamBuilder<List<order_model.Order>>(
                    stream: DatabaseService().getUserOrders(user?.id ?? ''),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(AppDesignSystem.primaryGold),
                            ),
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.inbox_outlined,
                                    size: 48,
                                    color: AppDesignSystem.primaryGold,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No orders yet',
                                    style: AppDesignSystem.headlineSmall.copyWith(
                                      color: AppDesignSystem.primaryGold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Create your first order to get started with our delivery service.',
                                    style: AppDesignSystem.bodyMedium.copyWith(
                                      color: AppDesignSystem.textSecondary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const CreateOrderScreen(),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppDesignSystem.primaryGold,
                                      foregroundColor: AppDesignSystem.backgroundDark,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text('Create First Order'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }

                      return Column(
                        children: snapshot.data!.take(3).map((order) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppDesignSystem.backgroundSurface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.local_shipping,
                                  color: AppDesignSystem.primaryGold,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Order #${order.id.substring(0, 8)}',
                                        style: AppDesignSystem.bodyLarge.copyWith(
                                          color: AppDesignSystem.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        order.status.toString().split('.').last,
                                        style: AppDesignSystem.bodySmall.copyWith(
                                          color: AppDesignSystem.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.arrow_forward_ios,
                                    color: AppDesignSystem.textMuted,
                                    size: 16,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const TrackingScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppDesignSystem.backgroundCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppDesignSystem.bodyLarge.copyWith(
                color: AppDesignSystem.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppDesignSystem.bodySmall.copyWith(
                color: AppDesignSystem.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OrdersTab extends StatelessWidget {
  final VoidCallback onNavigateToTracking;
  
  const OrdersTab({super.key, required this.onNavigateToTracking});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundDark,
      appBar: AppBar(
        title: Text(
          'My Orders',
          style: AppDesignSystem.headlineSmall.copyWith(
            color: AppDesignSystem.textPrimary,
          ),
        ),
        backgroundColor: AppDesignSystem.primaryGold,
        foregroundColor: AppDesignSystem.backgroundDark,
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'Orders will be listed here',
          style: TextStyle(color: AppDesignSystem.textPrimary),
        ),
      ),
    );
  }
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesignSystem.backgroundDark,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: AppDesignSystem.headlineSmall.copyWith(
            color: AppDesignSystem.textPrimary,
          ),
        ),
        backgroundColor: AppDesignSystem.primaryGold,
        foregroundColor: AppDesignSystem.backgroundDark,
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'Profile settings will be here',
          style: TextStyle(color: AppDesignSystem.textPrimary),
        ),
      ),
    );
  }
}
