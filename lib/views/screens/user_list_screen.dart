import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/user_controller.dart';
import '../../models/user_model.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final _searchController = TextEditingController();
  String _selectedRole = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showRoleDialog(BuildContext context, User user, UserController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change User Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('User'),
              leading: Radio<String>(
                value: 'user',
                groupValue: user.role,
                onChanged: (value) async {
                  Navigator.pop(context);
                  final success = await controller.updateUserRole(user.id, value!);
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Role updated successfully')),
                    );
                  }
                },
              ),
            ),
            ListTile(
              title: const Text('Owner'),
              leading: Radio<String>(
                value: 'owner',
                groupValue: user.role,
                onChanged: (value) async {
                  Navigator.pop(context);
                  final success = await controller.updateUserRole(user.id, value!);
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Role updated successfully')),
                    );
                  }
                },
              ),
            ),
            ListTile(
              title: const Text('Admin'),
              leading: Radio<String>(
                value: 'admin',
                groupValue: user.role,
                onChanged: (value) async {
                  Navigator.pop(context);
                  final success = await controller.updateUserRole(user.id, value!);
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Role updated successfully')),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, User user, UserController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.username}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await controller.deleteUser(user.id);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User deleted successfully')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final filteredUsers = controller.users.where((user) {
          if (_selectedRole != 'all' && user.role != _selectedRole) {
            return false;
          }
          if (_searchController.text.isNotEmpty) {
            return user.username.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                   user.email.toLowerCase().contains(_searchController.text.toLowerCase());
          }
          return true;
        }).toList();

        return Column(
          children: [
            // Search and Filter Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Search Field
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search users...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Role Filter
                  DropdownButton<String>(
                    value: _selectedRole,
                    items: const [
                      DropdownMenuItem(
                        value: 'all',
                        child: Text('All Roles'),
                      ),
                      DropdownMenuItem(
                        value: 'user',
                        child: Text('Users'),
                      ),
                      DropdownMenuItem(
                        value: 'owner',
                        child: Text('Owners'),
                      ),
                      DropdownMenuItem(
                        value: 'admin',
                        child: Text('Admins'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedRole = value!;
                      });
                    },
                  ),
                ],
              ),
            ),

            // User List
            Expanded(
              child: filteredUsers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_search,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No users found',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.grey[200],
                              child: Icon(
                                user.role == 'admin'
                                    ? Icons.admin_panel_settings
                                    : user.role == 'owner'
                                        ? Icons.business
                                        : Icons.person,
                                color: Colors.grey[800],
                              ),
                            ),
                            title: Text(user.username),
                            subtitle: Text(user.email),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getRoleColor(user.role),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    user.role.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _getRoleTextColor(user.role),
                                    ),
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'role',
                                      child: Text('Change Role'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete User'),
                                    ),
                                  ],
                                  onSelected: (value) {
                                    if (value == 'role') {
                                      _showRoleDialog(context, user, controller);
                                    } else if (value == 'delete') {
                                      _showDeleteDialog(context, user, controller);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.blue[100]!;
      case 'owner':
        return Colors.green[100]!;
      default:
        return Colors.grey[100]!;
    }
  }

  Color _getRoleTextColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.blue[900]!;
      case 'owner':
        return Colors.green[900]!;
      default:
        return Colors.grey[900]!;
    }
  }
} 