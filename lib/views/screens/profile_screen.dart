import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    final isAdmin = user?.role == 'admin';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey[200],
                child: Icon(
                  isAdmin ? Icons.admin_panel_settings : Icons.person,
                  size: 40,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.username ?? '',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isAdmin ? Colors.blue[100] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isAdmin ? 'Admin' : 'User',
                        style: TextStyle(
                          fontSize: 12,
                          color: isAdmin ? Colors.blue[900] : Colors.grey[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Profile Menu
          _buildMenuSection(
            title: 'Account',
            items: [
              _MenuItem(
                icon: Icons.person_outline,
                title: 'Edit Profile',
                onTap: () {
                  // TODO: Navigate to edit profile
                },
              ),
              _MenuItem(
                icon: Icons.lock_outline,
                title: 'Change Password',
                onTap: () {
                  // TODO: Navigate to change password
                },
              ),
              if (isAdmin) ...[
                _MenuItem(
                  icon: Icons.settings_outlined,
                  title: 'Admin Settings',
                  onTap: () {
                    // TODO: Navigate to admin settings
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),
          
          _buildMenuSection(
            title: 'Preferences',
            items: [
              _MenuItem(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                onTap: () {
                  // TODO: Navigate to notifications settings
                },
              ),
              _MenuItem(
                icon: Icons.language_outlined,
                title: 'Language',
                onTap: () {
                  // TODO: Navigate to language settings
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          _buildMenuSection(
            title: 'Other',
            items: [
              _MenuItem(
                icon: Icons.help_outline,
                title: 'Help Center',
                onTap: () {
                  // TODO: Navigate to help center
                },
              ),
              _MenuItem(
                icon: Icons.info_outline,
                title: 'About',
                onTap: () {
                  // TODO: Navigate to about page
                },
              ),
              _MenuItem(
                icon: Icons.logout,
                title: 'Logout',
                onTap: () {
                  context.read<AuthController>().logout();
                  Navigator.pushReplacementNamed(context, '/');
                },
                textColor: Colors.red,
                iconColor: Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection({
    required String title,
    required List<_MenuItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: items.map((item) => item).toList(),
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? textColor;
  final Color? iconColor;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? Colors.grey[600],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontSize: 14,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Colors.grey[400],
      ),
      onTap: onTap,
    );
  }
} 