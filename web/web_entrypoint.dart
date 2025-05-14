import 'package:flutter/material.dart'; // For runApp and UI
import 'package:firebase_core/firebase_core.dart'; // For Firebase initialization
import 'package:grocery_budget_planner/main.dart';

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Ensure Flutter bindings are initialized
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(const MyApp()); // Start the app with MyApp
}
