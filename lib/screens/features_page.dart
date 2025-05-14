import 'package:flutter/material.dart';

class FeaturesPage extends StatelessWidget {
  const FeaturesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.teal[700],
        title: const Text(
          "Features",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                "Explore Our Features",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1,
                children: [
                  _FeatureCard(
                    title: "Budget Management",
                    description:
                        "Set a grocery budget & track spending in real-time.",
                    imageAsset: 'assets/budget.jpg',
                  ),
                  _FeatureCard(
                    title: "Expense Tracking",
                    description:
                        "Categorize & view detailed expense records anytime.",
                    imageAsset: 'assets/expense.jpg',
                  ),
                  _FeatureCard(
                    title: "Price Comparison",
                    description:
                        "Compare grocery prices to find the best deals.",
                    imageAsset: 'assets/price.jpg',
                  ),
                  _FeatureCard(
                    title: "AI Cost-Saving Tips",
                    description:
                        "Get AI-powered suggestions to optimize your budget.",
                    imageAsset: 'assets/ai.jpg',
                  ),
                  _FeatureCard(
                    title: "Shopping List",
                    description:
                        "Plan and organize your grocery purchases easily.",
                    imageAsset: 'assets/list.jpg',
                  ),
                  _FeatureCard(
                    title: "Pantry Management",
                    description:
                        "Track pantry stock and reduce food waste effectively.",
                    imageAsset: 'assets/pantry.jpg',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final String description;
  final String imageAsset;

  const _FeatureCard({
    required this.title,
    required this.description,
    required this.imageAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.asset(
              imageAsset,
              height: 100,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
