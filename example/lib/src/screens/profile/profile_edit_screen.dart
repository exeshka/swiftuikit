import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:swiftuikit/swiftuikit.dart';

@RoutePage()
class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _nameController = TextEditingController(text: 'Alex Morgan');
  final _usernameController = TextEditingController(text: '@alexmorgan');
  final _bioController = TextEditingController(
    text: 'Coffee enthusiast & pastry lover',
  );
  final _emailController = TextEditingController(text: 'alex@example.com');
  final _phoneController = TextEditingController(text: '+1 (555) 123-4567');

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scrollController =
        SwiftSheetScrollProvider.maybeOf(context)?.controller;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: CupertinoNavigationBar(
        backgroundColor: Colors.black,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.maybePop(context),
          child: const Icon(CupertinoIcons.back, color: Colors.white),
        ),
        middle: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {},
          child: const Text(
            'Save',
            style: TextStyle(
              color: Color(0xFF007AFF),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        controller: scrollController,
        child: Column(
          children: [
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () {},
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6B3A2A), Color(0xFFC49A6C)],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 3,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        CupertinoIcons.person_fill,
                        size: 46,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF007AFF),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.black,
                          width: 3,
                        ),
                      ),
                      child: const Icon(
                        CupertinoIcons.camera_fill,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            _EditField(
              label: 'Full Name',
              controller: _nameController,
              icon: CupertinoIcons.person_fill,
            ),
            _EditField(
              label: 'Username',
              controller: _usernameController,
              icon: CupertinoIcons.at,
            ),
            _EditField(
              label: 'Bio',
              controller: _bioController,
              icon: CupertinoIcons.text_alignleft,
              maxLines: 3,
            ),
            _EditField(
              label: 'Email',
              controller: _emailController,
              icon: CupertinoIcons.envelope_fill,
              keyboardType: TextInputType.emailAddress,
            ),
            _EditField(
              label: 'Phone',
              controller: _phoneController,
              icon: CupertinoIcons.phone_fill,
              keyboardType: TextInputType.phone,
            ),

            const SizedBox(height: 40),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFFF3B30).withValues(alpha: 0.3),
                ),
              ),
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 14),
                onPressed: () {},
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.delete, color: Color(0xFFFF3B30), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Delete Account',
                      style: TextStyle(
                        color: Color(0xFFFF3B30),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final int? maxLines;
  final TextInputType? keyboardType;

  const _EditField({
    required this.label,
    required this.controller,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Row(
              children: [
                Icon(icon, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          CupertinoTextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
            ),
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(color: Colors.transparent),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
          ),
        ],
      ),
    );
  }
}
