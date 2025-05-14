import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Help"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Frequently Asked Questions",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ExpansionTile(
              title: const Text("How do I set a budget?"),
              children: const [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                      "To set a budget, navigate to the Budget Management screen and enter your desired monthly budget."),
                )
              ],
            ),
            ExpansionTile(
              title: const Text("How do I add an expense?"),
              children: const [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                      "To add an expense, go to the Expense Tracking screen and log your expense details."),
                )
              ],
            ),
            ExpansionTile(
              title: const Text("How do I join a shared budget?"),
              children: const [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                      "To join a shared budget, tap the 'Join Shared Budget' button from the Home screen and enter the provided join code."),
                )
              ],
            ),
            ExpansionTile(
              title: const Text("How do I export my data?"),
              children: const [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                      "To export your data, navigate to the Export & Reporting screen and follow the instructions to generate and share a CSV file."),
                )
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              "For further assistance, please contact support@yourapp.com",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
