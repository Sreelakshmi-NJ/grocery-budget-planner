import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;

  // You can later load these values from persistent storage (e.g., SharedPreferences or Firestore)
  // and update your app theme accordingly.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text("Dark Mode"),
            secondary: const Icon(Icons.dark_mode),
            value: _isDarkMode,
            onChanged: (bool value) {
              setState(() {
                _isDarkMode = value;
                // TODO: Integrate with theme management to update the app's theme.
              });
            },
          ),
          SwitchListTile(
            title: const Text("Enable Notifications"),
            secondary: const Icon(Icons.notifications),
            value: _notificationsEnabled,
            onChanged: (bool value) {
              setState(() {
                _notificationsEnabled = value;
                // TODO: Integrate with your notification settings.
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_circle),
            title: const Text("Account Settings"),
            onTap: () {
              // TODO: Navigate to account settings screen.
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text("Privacy Policy"),
            onTap: () {
              // TODO: Open a privacy policy page or dialog.
            },
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text("Terms & Conditions"),
            onTap: () {
              // TODO: Open terms & conditions page or dialog.
            },
          ),
        ],
      ),
    );
  }
}
