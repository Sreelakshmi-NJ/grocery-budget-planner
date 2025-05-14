import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  _AdminHomeScreenState createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;
  bool _isRailExtended = true;

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during logout: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }
    return Scaffold(
      // Top AppBar with Logout button
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.teal[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      // Main body as a Row with NavigationRail and content
      body: Row(
        children: [
          // Persistent NavigationRail
          NavigationRail(
            extended: _isRailExtended,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
                // Navigate based on index
                switch (index) {
                 case 0:
                     //Dashboard (current screen)
                    break;
                 case 1:
                    Navigator.pushNamed(context, '/admin-reports');
                    break;
                  case 2:
                    Navigator.pushNamed(context, '/manage-users');
                    break;
                  case 3:
                    Navigator.pushNamed(context, '/category-management');
                    break;
                  case 4:
                    Navigator.pushNamed(context, '/budget-monitoring');
                    break;
                  case 5:
                    _logout();
                    break;
                }
              });
            },
            leading: Column(
              children: [
                const SizedBox(height: 8),
                // Profile avatar with first letter of email
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white,
                  child: Text(
                    (user.email ?? 'A')[0].toUpperCase(),
                    style: const TextStyle(fontSize: 24, color: Colors.teal),
                  ),
                ),
                const SizedBox(height: 4),
                if (_isRailExtended)
                  Text(
                    user.email ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                IconButton(
                  icon: Icon(
                    _isRailExtended
                        ? Icons.arrow_back_ios
                        : Icons.arrow_forward_ios,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _isRailExtended = !_isRailExtended;
                    });
                  },
                ),
              ],
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.analytics),
                label: Text('Reports'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.group),
                label: Text('Users'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.category),
                label: Text('Categories'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.account_balance_wallet),
                label: Text('Budgets'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.logout),
                label: Text('Logout'),
              ),
            ],
          ),
          // Main Content Area
          Expanded(
            child: Stack(
              children: [
                // Background image
                Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/admin_bg.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Semi-transparent overlay for readability
                Container(
                  color: Colors.black.withOpacity(0.5),
                ),
                // Content scroll view
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      const Text(
                        'Welcome, Admin!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Manage your application and monitor user activities',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Grid of admin functions
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.3,
                        children: [
                        _buildAdminCard(
                            context,
                            icon: Icons.analytics,
                            title: 'Reports & Analytics',
                            description: 'View detailed user and expense analytics',
                            onTap: () {
                              Navigator.pushNamed(context, '/admin-reports');
                            },
                          ),
                          _buildAdminCard(
                            context,
                            icon: Icons.group,
                            title: 'User Management',
                            description: 'Manage users and roles',
                            onTap: () {
                              Navigator.pushNamed(context, '/manage-users');
                            },
                          ),
                          _buildAdminCard(
                            context,
                            icon: Icons.category,
                            title: 'Category Management',
                            description: 'Manage expense categories',
                            onTap: () {
                              Navigator.pushNamed(context, '/category-management');
                            },
                          ),
                          _buildAdminCard(
                            context,
                            icon: Icons.account_balance_wallet,
                            title: 'Budget Monitoring',
                            description: 'Monitor user budgets and spending',
                            onTap: () {
                              Navigator.pushNamed(context, '/budget-monitoring');
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Helper method to build an admin card with description
  Widget _buildAdminCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: Colors.teal),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
