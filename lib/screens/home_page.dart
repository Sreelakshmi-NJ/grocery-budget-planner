import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // TOP NAVBAR with a teal background
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.teal[700],
        title: const Text(
          "Grocery Budget Planner",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          _NavItem(
            title: "Features",
            onTap: () => Navigator.pushNamed(context, "/features"),
          ),
          _NavItem(
            title: "About",
            onTap: () => Navigator.pushNamed(context, "/about"),
          ),
          _NavItem(
            title: "Login",
            onTap: () => Navigator.pushNamed(context, "/login"),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, "/signup"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.teal[700],
              ),
              child: const Text("Sign Up"),
            ),
          ),
        ],
      ),

      // MAIN BODY
      body: SingleChildScrollView(
        child: Column(
          children: [
            // HERO SECTION WITH BACKGROUND IMAGE + DARK OVERLAY
            Container(
              width: double.infinity,
              // Outer container with the background image
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: const AssetImage('assets/background.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                // Increased opacity from 0.35 to 0.55
                color: Colors.black.withOpacity(0.55),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 60,
                    horizontal: 20,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Title
                      Text(
                        "PLAN. TRACK. SAVE.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              offset: const Offset(1, 2),
                              blurRadius: 4,
                              color: Colors.black38,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Subtitle
                      Text(
                        "Your Complete Grocery Budget Guide.\nPlan your groceries, track your spending, and save money effortlessly with Grocery Budget Planner.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                          shadows: [
                            Shadow(
                              offset: const Offset(1, 1),
                              blurRadius: 3,
                              color: Colors.black26,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Centered hero image with shadow
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black45,
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/hero.jpg',
                            height: 220,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // CTA Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () =>
                                Navigator.pushNamed(context, "/signup"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.teal[800],
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 24,
                              ),
                            ),
                            child: const Text(
                              "Get Started",
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                          const SizedBox(width: 20),
                          OutlinedButton(
                            onPressed: () =>
                                Navigator.pushNamed(context, "/how_it_works"),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white),
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 24,
                              ),
                            ),
                            child: const Text(
                              "Learn More",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // FEATURES SECTION
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              child: Column(
                children: [
                  const Text(
                    "What We Offer",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Our platform is packed with features designed to make your grocery budgeting simple and stress-free.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[700], fontSize: 15),
                  ),
                  const SizedBox(height: 20),

                  // Center + ConstrainedBox to limit max width
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // For smaller screens, 1 column; for medium screens, 2 columns
                          int crossAxisCount = 1;
                          if (constraints.maxWidth > 800) {
                            crossAxisCount = 2;
                          }

                          return GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.2,
                            children: [
                              _FeatureTile(
                                title: "Budget Management",
                                description:
                                    "Set a grocery budget & track spending in real-time.",
                                imageAsset: 'assets/budget.jpg',
                              ),
                              _FeatureTile(
                                title: "Expense Tracking",
                                description:
                                    "Categorize & view detailed expense records anytime.",
                                imageAsset: 'assets/expense.jpg',
                              ),
                              _FeatureTile(
                                title: "Price Comparison",
                                description:
                                    "Compare grocery prices to find the best deals.",
                                imageAsset: 'assets/price.jpg',
                              ),
                              _FeatureTile(
                                title: "AI Cost-Saving Tips",
                                description:
                                    "Get AI-powered suggestions to optimize your budget.",
                                imageAsset: 'assets/ai.jpg',
                              ),
                              _FeatureTile(
                                title: "Shopping List",
                                description:
                                    "Plan and organize your grocery purchases easily.",
                                imageAsset: 'assets/list.jpg',
                              ),
                              _FeatureTile(
                                title: "Pantry Management",
                                description:
                                    "Track pantry stock and reduce food waste effectively.",
                                imageAsset: 'assets/pantry.jpg',
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // FOOTER SECTION with teal background
            Container(
              color: Colors.teal[800],
              padding: const EdgeInsets.all(30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "Grocery Budget Planner",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 30,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      _FooterItem(
                        title: "Features",
                        onTap: () => Navigator.pushNamed(context, "/features"),
                      ),
                      /* _FooterItem(
                        title: "How It Works",
                        onTap: () =>
                            Navigator.pushNamed(context, "/how_it_works"),
                      ),*/
                      _FooterItem(
                        title: "About",
                        onTap: () => Navigator.pushNamed(context, "/about"),
                      ),
                      _FooterItem(
                        title: "Login",
                        onTap: () => Navigator.pushNamed(context, "/login"),
                      ),
                      _FooterItem(
                        title: "Sign Up",
                        onTap: () => Navigator.pushNamed(context, "/signup"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    "Connect With Us",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Email: support@groceryplanner.com  |  Phone: +1 234 567 890",
                    style: TextStyle(color: Colors.white60),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "Location: 123 Grocery Street, Food City, USA",
                    style: TextStyle(color: Colors.white60),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(LucideIcons.facebook, color: Colors.white),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: Icon(LucideIcons.instagram, color: Colors.white),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: Icon(LucideIcons.twitter, color: Colors.white),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "© 2025 Grocery Budget Planner. All Rights Reserved.",
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// FEATURE TILE (Text first, then image)
class _FeatureTile extends StatelessWidget {
  final String title;
  final String description;
  final String imageAsset;

  const _FeatureTile({
    required this.title,
    required this.description,
    required this.imageAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            // Title
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),

            // Description
            Text(
              description,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            // Feature Image
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  imageAsset,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// NAVIGATION ITEM
class _NavItem extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _NavItem({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: Text(title, style: const TextStyle(color: Colors.white)),
    );
  }
}

// FOOTER LINK ITEM
class _FooterItem extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _FooterItem({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        title,
        style: const TextStyle(color: Colors.white70, fontSize: 16),
      ),
    );
  }
}
