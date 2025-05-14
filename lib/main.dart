import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:grocery_budget_planner/screens/gamificaton_screen.dart';
import 'firebase_options.dart';
import 'screens/admin_home_screen.dart';
import 'screens/admin_login_screen.dart';
import 'screens/admin_reports_screen.dart';
import 'screens/admin_category_management_screen.dart';
import 'screens/admin_budget_monitoring_screen.dart';
import 'screens/admin_user_management_screen.dart';
// Import login_screen with a prefix to avoid ambiguity if LoginScreen is also defined in home_page.dart.
import 'screens/login_screen.dart' as login_screen;
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
//import 'screens/settings_screen.dart';
import 'screens/help_screen.dart';
import 'screens/budget_management_screen.dart';
import 'screens/expense_tracking_screen.dart';
import 'screens/shopping_list_screen.dart';
import 'screens/price_comparison_screen.dart';
import 'screens/ai_suggestions_screen.dart';
import 'screens/pantry_management_screen.dart';
import 'screens/budget_insights_screen.dart';
import 'screens/meal_planning_screen.dart';
import 'screens/export_reporting_screen.dart';
import 'screens/shared_budget_screen.dart';
// Import home_page with a prefix if needed.
import 'screens/home_page.dart' as home_page;
import 'screens/features_page.dart';
import 'screens/about_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Error initializing Firebase: $e');
  }
  runApp(const MyApp());
}

class PlaceholderPage extends StatelessWidget {
  final String title;
  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Text('$title Page Placeholder'),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grocery Budget Planner',
      debugShowCheckedModeBanner: false, // Remove debug banner
      theme: ThemeData(
        primarySwatch: Colors.teal, // Match your app's color scheme
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      // Reference HomePage from the home_page.dart file
      home: home_page.HomePage(),
      routes: {
        '/signup': (context) => const SignUpScreen(),
        '/login': (context) => const login_screen.LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/features': (context) => const PlaceholderPage(title: 'Features'),
        '/about': (context) => const PlaceholderPage(title: 'About'),
        '/faq': (context) => const PlaceholderPage(title: 'FAQ'),
        //'/how': (context) => const PlaceholderPage(title: 'How It Works'),
        '/admin-login': (context) => const AdminLoginScreen(),
        '/admin-home': (context) => const AdminHomeScreen(),
        '/admin-reports': (context) => const AdminReportsScreen(),
        '/category-management': (context) =>
            const AdminCategoryManagementScreen(),
        '/budget-monitoring': (context) => const AdminBudgetMonitoringScreen(),
        '/manage-users': (context) => const AdminUserManagementScreen(),
        '/profile': (context) => const ProfileScreen(),
        //'/settings': (context) => const SettingsScreen(),
        '/help': (context) => const HelpScreen(),
        '/budget': (context) => const BudgetManagementScreen(),
        '/expense': (context) => const ExpenseTrackingScreen(),
        '/shopping': (context) => const ShoppingListScreen(),
        '/price': (context) => PriceComparisonScreen(),
        '/ai': (context) => const AISuggestionsScreen(),
        '/pantry': (context) => const PantryManagementScreen(),
        '/insights': (context) => const BudgetInsightsScreen(),
        '/meal': (context) => const MealPlanningScreen(),
        '/gamification': (context) => const GamificationScreen(),
        '/shared': (context) => const SharedBudgetScreen(),
        '/export': (context) => const ExportReportingScreen(),
        // ignore: equal_keys_in_map
        '/features': (context) => const FeaturesPage(),
        // ignore: equal_keys_in_map
        '/about': (context) => const AboutPage(),
      },
    );
  }
}
