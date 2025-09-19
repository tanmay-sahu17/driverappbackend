import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/location_provider.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme Section
          _buildSectionHeader(
            context, 
            'Appearance', 
            Icons.palette,
          ),
          const SizedBox(height: 12),
          _buildThemeSelector(context),
          
          const SizedBox(height: 32),
          
          // About Section
          _buildSectionHeader(
            context, 
            'Information', 
            Icons.info,
          ),
          const SizedBox(height: 12),
          _buildInfoSection(context),
          
          const SizedBox(height: 32),
          
          // Account Section (with logout)
          _buildSectionHeader(
            context, 
            'Account', 
            Icons.person,
          ),
          const SizedBox(height: 12),
          _buildAccountSection(context),
          
          const SizedBox(height: 32),
          
          // Developer Section
          _buildSectionHeader(
            context, 
            'Developer', 
            Icons.code,
          ),
          const SizedBox(height: 12),
          _buildDeveloperSection(context),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: Theme.of(context).primaryColor,
          size: 24,
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSection(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Card(
          elevation: isDarkMode ? 4 : 2,
          child: Column(
            children: [
              // User Info
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: isDarkMode ? const Color(0xFF6CB5A8) : const Color(0xFF4A9B8E),
                  child: Text(
                    (authProvider.user?.displayName ?? 'D')[0].toUpperCase(),
                    style: TextStyle(
                      color: isDarkMode ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  authProvider.user?.displayName ?? 'Driver',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  authProvider.user?.email ?? '',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.grey[600],
                  ),
                ),
              ),
              Divider(
                height: 1,
                color: isDarkMode ? Colors.white24 : Colors.grey[300],
              ),
              // Logout Option
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: isDarkMode ? Colors.red[900] : Colors.red[50],
                  child: Icon(
                    Icons.logout,
                    color: Colors.red[600],
                    size: 20,
                  ),
                ),
                title: Text(
                  'Sign Out',
                  style: TextStyle(
                    color: Colors.red[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'Logout from your account',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.red[400],
                ),
                onTap: () => _handleSignOut(context),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleSignOut(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    
    // Stop tracking before signing out
    locationProvider.stopTracking();
    
    // Sign out
    await authProvider.signOut();
    
    // Navigate to login screen immediately
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Widget _buildThemeSelector(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Card(
          elevation: isDarkMode ? 4 : 2,
          color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isDarkMode 
                  ? const Color(0xFF6CB5A8).withValues(alpha: 0.2)
                  : const Color(0xFF4A9B8E).withValues(alpha: 0.1),
              radius: 20,
              child: Icon(
                themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                color: isDarkMode ? const Color(0xFF6CB5A8) : const Color(0xFF4A9B8E),
                size: 20,
              ),
            ),
            title: Text(
              'Dark Mode',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: isDarkMode ? Colors.white : Colors.grey[800],
              ),
            ),
            subtitle: Text(
              themeProvider.isDarkMode ? 'Dark theme enabled' : 'Light theme enabled',
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            trailing: Switch.adaptive(
              value: themeProvider.isDarkMode,
              onChanged: (bool value) {
                if (value) {
                  themeProvider.setThemeMode(ThemeMode.dark);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.dark_mode, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text('Switched to Dark Mode'),
                        ],
                      ),
                      backgroundColor: Colors.grey[800],
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                } else {
                  themeProvider.setThemeMode(ThemeMode.light);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.light_mode, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text('Switched to Light Mode'),
                        ],
                      ),
                      backgroundColor: Colors.blue[600],
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              activeThumbColor: const Color(0xFF6CB5A8),
              activeTrackColor: const Color(0xFF6CB5A8).withValues(alpha: 0.3),
              inactiveThumbColor: Colors.grey[400],
              inactiveTrackColor: Colors.grey[300],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      elevation: isDarkMode ? 4 : 2,
      child: Column(
        children: [
          // About Us
          ListTile(
            leading: CircleAvatar(
              backgroundColor: isDarkMode ? Colors.blue[900] : Colors.blue[50],
              child: Icon(
                Icons.info_outline,
                color: Colors.blue[600],
                size: 20,
              ),
            ),
            title: const Text(
              'About Us',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              'Learn more about our app',
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.grey[600],
                fontSize: 12,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDarkMode ? Colors.white54 : Colors.grey[400],
            ),
            onTap: () => _showAboutDialog(context),
          ),
          Divider(
            height: 1,
            color: isDarkMode ? Colors.white24 : Colors.grey[300],
          ),
          // Contact Owner
          ListTile(
            leading: CircleAvatar(
              backgroundColor: isDarkMode ? Colors.green[900] : Colors.green[50],
              child: Icon(
                Icons.contact_support,
                color: Colors.green[600],
                size: 20,
              ),
            ),
            title: const Text(
              'Contact Owner',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              'Get in touch with us',
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.grey[600],
                fontSize: 12,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDarkMode ? Colors.white54 : Colors.grey[400],
            ),
            onTap: () => _showContactDialog(context),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.directions_bus,
                color: Theme.of(context).primaryColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Bus Driver App',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Version 1.0.0',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'A comprehensive bus driver tracking application designed to help drivers manage their routes, track locations, and provide real-time updates to passengers.',
                style: TextStyle(height: 1.5),
              ),
              SizedBox(height: 16),
              Text(
                'Features:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text('• Real-time GPS tracking'),
              Text('• Route management'),
              Text('• Emergency SOS'),
              Text('• Dark/Light themes'),
              Text('• User-friendly interface'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.contact_support,
                color: Theme.of(context).primaryColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Contact Us',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.email, color: Colors.blue),
                title: Text('Email'),
                subtitle: Text('support@busdriverapp.com'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.phone, color: Colors.green),
                title: Text('Phone'),
                subtitle: Text('+91 98765 43210'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.language, color: Colors.orange),
                title: Text('Website'),
                subtitle: Text('www.busdriverapp.com'),
              ),
              SizedBox(height: 8),
              Text(
                'Business Hours: 9:00 AM - 6:00 PM (Mon-Fri)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDeveloperSection(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      elevation: isDarkMode ? 4 : 2,
      color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isDarkMode 
              ? const Color(0xFF6CB5A8).withValues(alpha: 0.2)
              : const Color(0xFF4A9B8E).withValues(alpha: 0.1),
          radius: 20,
          child: Icon(
            Icons.bug_report,
            color: isDarkMode ? const Color(0xFF6CB5A8) : const Color(0xFF4A9B8E),
            size: 20,
          ),
        ),
        title: Text(
          'API Debug',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          'Test backend API connection',
          style: TextStyle(
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            fontSize: 13,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
        ),
        onTap: () {
          Navigator.pushNamed(context, '/debug');
        },
      ),
    );
  }
}
