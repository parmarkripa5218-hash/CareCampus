import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/user_model.dart';
import '../../services/services.dart';
import '../../utils/theme.dart';
import '../../utils/validators.dart';

class ManageUsers extends StatefulWidget {
  const ManageUsers({super.key});

  @override
  State<ManageUsers> createState() => _ManageUsersState();
}

class _ManageUsersState extends State<ManageUsers> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'student';

  List<AppUser> _allUsers = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _obscureNewPassword = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final list = await Services.db.getAllUsers();
      setState(() {
        _allUsers = list;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final name = Validators.sanitizeText(_nameController.text);
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    try {
      final createdUser = await Services.auth.createUser(
        name: name,
        username: username,
        password: password,
        role: _selectedRole,
      );

      _nameController.clear();
      _usernameController.clear();
      _passwordController.clear();

      _loadUsers();

      if (!mounted) return;

      // Dialog showing credentials details with a Copy option
      showDialog(
        context: context,
        builder: (context) {
          final shareText =
              'CareCampus Account Created!\nRole: ${createdUser.role.toUpperCase()}\nName: ${createdUser.name}\nUsername: ${createdUser.username}\nPassword: $password';
          return AlertDialog(
            backgroundColor: AppTheme.slateDark,
            title: const Text('Account Registered Successfully'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'User Registered: ${createdUser.name}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Username: ${createdUser.username}'),
                Text('Password: $password'),
                Text('Role: ${createdUser.role.toUpperCase()}'),
                const SizedBox(height: 16),
                const Text(
                  'Share these credentials securely with the user.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textLow),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.copy_all_rounded),
                label: const Text('Copy Credentials'),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: shareText));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Credentials copied to clipboard!'),
                      backgroundColor: AppTheme.alertSuccess,
                    ),
                  );
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppTheme.alertSevere,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _deleteUser(AppUser user) async {
    // Prevent deleting admin accounts
    if (user.role == 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admin accounts cannot be deleted.'),
          backgroundColor: AppTheme.alertWarning,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.slateDark,
        title: const Text('Delete User Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to permanently delete the account for:',
              style: const TextStyle(color: AppTheme.textMedium),
            ),
            const SizedBox(height: 12),
            Text(
              user.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              user.username,
              style: const TextStyle(color: AppTheme.textLow, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.alertSevere.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.alertSevere.withValues(alpha: 0.2)),
              ),
              child: const Text(
                '⚠️ This action is permanent and cannot be undone.',
                style: TextStyle(color: AppTheme.alertSevere, fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.alertSevere,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.delete_forever_rounded, size: 18),
            label: const Text('Delete Account'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await Services.auth.deleteUser(user.uid);
        _loadUsers();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account for "${user.name}" has been deleted.'),
            backgroundColor: AppTheme.alertSevere,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        final errorText = e.toString();
        final isPermission = errorText.contains('permission-denied');
        if (isPermission) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppTheme.slateDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.shield_outlined, color: AppTheme.alertWarning),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Firestore Permission Denied',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Firebase Cloud Firestore blocked the delete operation because the updated security rules have not been published in your Firebase Console yet.',
                    style: TextStyle(color: AppTheme.textMedium, fontSize: 13, height: 1.4),
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Quick Fix Steps:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.tealPrimary),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '1. Open console.firebase.google.com\n'
                    '2. Select your CareCampus project\n'
                    '3. Go to Firestore Database > Rules\n'
                    '4. Replace rules with firestore.rules from this project\n'
                    '5. Click the "Publish" button',
                    style: TextStyle(fontSize: 12, height: 1.6),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Understood'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete user: $errorText'),
              backgroundColor: AppTheme.alertSevere,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
      ),
      body: Container(
        height: double.infinity,
        decoration: AppTheme.backgroundGradient,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.tealPrimary))
            : isDesktop
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: _buildCreateFormCard()),
                        const SizedBox(width: 24),
                        Expanded(flex: 3, child: _buildUsersListCard()),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildCreateFormCard(),
                        const SizedBox(height: 20),
                        _buildUsersListCard(),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildCreateFormCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassCardDecoration(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add Student or Counsellor',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: AppTheme.mintAccent),
            ),
            const SizedBox(height: 20),

            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: (v) => Validators.validateRequired(v, 'Name', maxLen: 60),
            ),
            const SizedBox(height: 16),

            // Username/Email
            TextFormField(
              controller: _usernameController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address / Username',
                prefixIcon: Icon(Icons.alternate_email_rounded),
              ),
              validator: Validators.validateEmail,
            ),
            const SizedBox(height: 16),

            // Password
            TextFormField(
              controller: _passwordController,
              obscureText: _obscureNewPassword,
              decoration: InputDecoration(
                labelText: 'Secure Password',
                prefixIcon: const Icon(Icons.password_rounded),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNewPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppTheme.textLow,
                  ),
                  onPressed: () =>
                      setState(() => _obscureNewPassword = !_obscureNewPassword),
                ),
              ),
              validator: Validators.validatePassword,
            ),
            const SizedBox(height: 16),

            // Role selection
            DropdownButtonFormField<String>(
              initialValue: _selectedRole,
              dropdownColor: AppTheme.slateCard,
              decoration: const InputDecoration(labelText: 'Account Role'),
              items: const [
                DropdownMenuItem(value: 'student', child: Text('Student')),
                DropdownMenuItem(value: 'counsellor', child: Text('Counsellor')),
              ],
              onChanged: (v) {
                if (v != null) {
                  setState(() {
                    _selectedRole = v;
                  });
                }
              },
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isSubmitting ? null : _createUser,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(AppTheme.spaceDark),
                      ),
                    )
                  : const Text('Create Account'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersListCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Registered Accounts (${_allUsers.length})',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          if (_allUsers.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No users registered yet.',
                  style: TextStyle(color: AppTheme.textLow),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _allUsers.length,
              separatorBuilder: (_, i) =>
                  const Divider(height: 20, color: Colors.white10),
              itemBuilder: (context, index) {
                final user = _allUsers[index];

                Color roleColor = AppTheme.tealPrimary;
                if (user.role == 'counsellor') roleColor = AppTheme.lilacAccent;
                if (user.role == 'admin') roleColor = AppTheme.mintAccent;

                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            user.username,
                            style: const TextStyle(
                              color: AppTheme.textLow,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: roleColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        user.role.toUpperCase(),
                        style: TextStyle(
                          color: roleColor,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Delete button — only for non-admin users
                    if (user.role != 'admin') ...[
                      const SizedBox(width: 6),
                      IconButton(
                        tooltip: 'Delete account',
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: AppTheme.alertSevere.withValues(alpha: 0.7),
                          size: 20,
                        ),
                        onPressed: () => _deleteUser(user),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ],
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
