import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.teal[700],
        title: const Text(
          "About Us",
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
                "About Grocery Budget Planner",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                "Grocery Budget Planner is your ultimate tool for managing grocery expenses. "
                "Our mission is to help you plan, track, and save money effortlessly while reducing food waste. "
                "With features like budget management, expense tracking, price comparison, and AI-powered tips, "
                "we aim to make grocery shopping stress-free and efficient.",
                style: TextStyle(fontSize: 16, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              /*Image.asset(
                'assets/about.jpg',
                height: 200,
                fit: BoxFit.cover,
              ),*/
              const SizedBox(height: 20),
              const Text(
                "Our Vision",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "To empower individuals and families to take control of their grocery budgets, "
                "reduce food waste, and make smarter financial decisions.",
                style: TextStyle(fontSize: 16, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                "Contact Us",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Email: support@groceryplanner.com\nPhone: +1 234 567 890\nLocation: 123 Grocery Street, Food City, USA",
                style: TextStyle(fontSize: 16, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
