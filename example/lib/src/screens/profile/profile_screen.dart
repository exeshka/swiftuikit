import 'package:auto_route/auto_route.dart';
import 'package:example/src/core/router/router.gr.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:swiftuikit/swiftuikit.dart';

@RoutePage()
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scrollController = SwiftSheetScrollProvider.maybeOf(context)?.controller;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: CupertinoNavigationBar(
        backgroundColor: Colors.black,
        middle: const Text(
          'Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => context.router.push(ProfileEditRoute()),
          child: const Icon(
            CupertinoIcons.square_grid_2x2,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        controller: scrollController,
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: 88,
              height: 88,
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
                  size: 40,
                  color: Colors.white70,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Alex Morgan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '@alexmorgan',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
            const SizedBox(height: 12),
            Text(
              'Coffee enthusiast & pastry lover',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                children: [
                  _StatItem(label: 'Orders', value: '24'),
                  _StatItem(label: 'Favorites', value: '18'),
                  _StatItem(label: 'Reviews', value: '12'),
                ],
              ),
            ),

            const SizedBox(height: 32),

            _SettingsTile(
              icon: CupertinoIcons.person_crop_circle,
              title: 'Edit Profile',
              onTap: () => context.router.push(ProfileEditRoute()),
            ),
            _SettingsTile(
              icon: CupertinoIcons.bell_fill,
              title: 'Notifications',
              trailing: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF3B30),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            _SettingsTile(
              icon: CupertinoIcons.creditcard_fill,
              title: 'Payment Methods',
            ),
            _SettingsTile(
              icon: CupertinoIcons.location_fill,
              title: 'Delivery Address',
            ),
            _SettingsTile(
              icon: CupertinoIcons.question_circle_fill,
              title: 'Help Center',
            ),
            _SettingsTile(
              icon: CupertinoIcons.gear_alt_fill,
              title: 'Settings',
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        onPressed: onTap ?? () {},
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: CupertinoTheme.of(
                  context,
                ).primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 18,
                color: CupertinoTheme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ?trailing,
            Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }
}
