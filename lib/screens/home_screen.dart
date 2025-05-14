import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isRailExtended = true;

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
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
      // Top AppBar with Logout
      appBar: AppBar(
        automaticallyImplyLeading: false, // no default back arrow
        title: const Text('Grocery Budget Planner'),
        backgroundColor: Colors.teal[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await _logout(context);
            },
          ),
        ],
      ),
      // Body with NavigationRail + content
      body: Row(
        children: [
          // NavigationRail for main navigation
          NavigationRail(
            extended: _isRailExtended,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
              // Navigate based on index
              switch (index) {
                case 0:
                  // This Home screen
                  break;
                case 1:
                  Navigator.pushNamed(context, '/profile');
                  break;
                case 2:
                  Navigator.pushNamed(context, '/settings');
                  break;
                case 3:
                  Navigator.pushNamed(context, '/help');
                  break;
                case 4:
                  _logout(context);
                  break;
              }
            },
            // Leading: user avatar and email when extended
            leading: _buildUserHeader(user),
            // Trailing: toggle button to expand/collapse the rail
            trailing: IconButton(
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
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.home),
                label: Text('Home'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.person),
                label: Text('Profile'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.help),
                label: Text('Help'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.logout),
                label: Text('Logout'),
              ),
            ],
          ),
          // Main Content
          Expanded(
            child: Stack(
              children: [
                // Background image
                Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/budget.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Semi-transparent overlay
                Container(color: Colors.black.withOpacity(0.5)),
                // Scrollable content
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // "Welcome Back!" + user name
                      const Text(
                        'Welcome Back!',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Hi, ${user.displayName ?? 'User'}! Manage your budget and expenses effortlessly.',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      // Grid of Feature Cards
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16.0,
                        mainAxisSpacing: 16.0,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.0,
                        children: [
                          _buildFeatureCard(
                            context,
                            icon: Icons.attach_money,
                            color: Colors.green,
                            title: 'Budget Management',
                            description: 'Set & manage budget',
                            route: '/budget',
                          ),
                          _buildFeatureCard(
                            context,
                            icon: Icons.add_chart,
                            color: Colors.redAccent,
                            title: 'Expense Tracking',
                            description: 'Log your expenses',
                            route: '/expense',
                          ),
                          _buildFeatureCard(
                            context,
                            icon: Icons.list,
                            color: Colors.indigo,
                            title: 'Shopping List',
                            description: 'Organize shopping items',
                            route: '/shopping',
                          ),
                          _buildFeatureCard(
                            context,
                            icon: Icons.compare,
                            color: Colors.deepPurple,
                            title: 'Price Comparison',
                            description: 'Compare store prices',
                            route: '/price',
                          ),
                          _buildFeatureCard(
                            context,
                            icon: Icons.lightbulb_outline,
                            color: Colors.amber,
                            title: 'AI Suggestions',
                            description: 'Smart recommendations',
                            route: '/ai',
                          ),
                          _buildFeatureCard(
                            context,
                            icon: Icons.kitchen,
                            color: Colors.blue,
                            title: 'Pantry Management',
                            description: 'Track pantry items',
                            route: '/pantry',
                          ),
                          _buildFeatureCard(
                            context,
                            icon: Icons.bar_chart,
                            color: Colors.teal,
                            title: 'Budget Insights',
                            description: 'Analyze spending',
                            route: '/insights',
                          ),
                          _buildFeatureCard(
                            context,
                            icon: Icons.restaurant,
                            color: Colors.deepOrange,
                            title: 'Meal Planning',
                            description: 'Plan your meals',
                            route: '/meal',
                          ),
                          _buildFeatureCard(
                            context,
                            icon: Icons.emoji_events,
                            color: Colors.purple,
                            title: 'Gamification',
                            description: 'Earn rewards',
                            route: '/gamification',
                          ),
                          _buildFeatureCard(
                            context,
                            icon: Icons.group,
                            color: Colors.lightBlue,
                            title: 'Shared Budgets',
                            description: 'Multi-user support',
                            route: '/shared',
                          ),
                          _buildFeatureCard(
                            context,
                            icon: Icons.upload_file,
                            color: Colors.grey,
                            title: 'Export & Reporting',
                            description: 'Export your data',
                            route: '/export',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16.0),
                      _buildOverviewCard(),
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

  /// Builds the user info in the NavigationRail leading
  Widget _buildUserHeader(User user) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        children: [
          // Profile avatar
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, color: Colors.teal),
                );
              }
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white,
                  child: Text(
                    (user.displayName ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(fontSize: 24, color: Colors.teal),
                  ),
                );
              }

              final data = snapshot.data!.data() as Map<String, dynamic>;
              final String? profileImageUrl = data['profileImage'];
              if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
                return CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage(profileImageUrl),
                );
              } else {
                return CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white,
                  child: Text(
                    (user.displayName ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(fontSize: 24, color: Colors.teal),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 4),
          if (_isRailExtended)
            Text(
              user.email ?? '',
              style: const TextStyle(color: Colors.white, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  /// Builds a feature card
  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    required String route,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, route);
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: color,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: Colors.white),
              const SizedBox(height: 4.0),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4.0),
              Text(
                description,
                style: const TextStyle(fontSize: 10, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds an optional overview card at the bottom
  Widget _buildOverviewCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Overview',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4.0),
            Text('Your budgets, expenses, and savings are all on track.'),
          ],
        ),
      ),
    );
  }
}
