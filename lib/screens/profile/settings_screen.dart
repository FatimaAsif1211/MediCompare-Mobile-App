import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../main.dart'; // Import themeNotifier

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _locationServices = true;

  void _showFeedback(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("App Settings", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 25),
        children: [
          _buildSectionHeader("Notifications & Alerts"),
          _buildSwitchTile(
            Icons.notifications_active_outlined,
            "Push Notifications",
            "Get alerts for medicine reminders",
            _notifications,
            (val) {
              setState(() => _notifications = val);
              _showFeedback(val ? "Notifications enabled" : "Notifications disabled");
            },
          ),
          _buildSwitchTile(
            Icons.location_on_outlined,
            "Location Services",
            "Find pharmacies near you",
            _locationServices,
            (val) {
              setState(() => _locationServices = val);
              _showFeedback(val ? "Location services enabled" : "Location services disabled");
            },
          ),
          SizedBox(height: 25),
          _buildSectionHeader("Appearance"),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (_, mode, __) {
              bool isDark = mode == ThemeMode.dark;
              return _buildSwitchTile(
                Icons.dark_mode_outlined,
                "Dark Mode",
                "Switch to a darker theme",
                isDark,
                (val) {
                  themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                  _showFeedback(val ? "Dark Mode enabled" : "Light Mode enabled");
                },
              );
            },
          ),
          SizedBox(height: 25),
          _buildSectionHeader("Security & Privacy"),
          _buildActionTile(
            Icons.lock_outline_rounded, 
            "Privacy Settings", 
            "Manage your data sharing",
            () => _showFeedback("Privacy Settings coming soon"),
          ),
          _buildActionTile(
            Icons.security_rounded, 
            "Account Security", 
            "Change password and 2FA",
            () => _showFeedback("Security options coming soon"),
          ),
          SizedBox(height: 25),
          _buildSectionHeader("App Info"),
          _buildActionTile(
            Icons.info_outline_rounded, 
            "Version", 
            "1.0.0 (Stable Build)",
            () => _showAboutDialog(context),
          ),
          _buildActionTile(
            Icons.description_outlined, 
            "Terms of Service", 
            "Read our usage policy",
            () => _showFeedback("Opening Terms of Service..."),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: "MediCompare",
      applicationVersion: "1.0.0",
      applicationIcon: Icon(Icons.medical_services_rounded, color: AppColors.primary, size: 40),
      children: [
        Text("Your medicine price comparison companion."),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(IconData icon, String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SwitchListTile(
        secondary: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        value: value,
        activeColor: AppColors.primary,
        onChanged: onChanged,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey[400]),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }
}
