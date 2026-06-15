import 'dart:async';

import 'package:booking/presentaion/auth/cubit/auth_cubit.dart';
import 'package:booking/presentaion/provider/pages/registration_screen.dart';
import 'package:booking/presentaion/screens/favorite/favorite_screen.dart';
import 'package:booking/presentaion/screens/profile/about.dart';
import 'package:booking/presentaion/screens/profile/policy.dart';
import 'package:booking/presentaion/screens/profile/terms.dart';
import 'package:booking/presentaion/theme/cubit/theme_cubit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

// Profile Screen
class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Timer? timer;
  bool isEmailVerified = false;

  @override
  void initState() {
    isEmailVerified = FirebaseAuth.instance.currentUser!.emailVerified;
    if (!isEmailVerified) {
      timer = Timer.periodic(
        const Duration(seconds: 3),
        (timer) => checkEmailVerification(),
      );
    }
    super.initState();
  }

  Future sendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      await user.sendEmailVerification();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future checkEmailVerification() async {
    // call after email verification
    await FirebaseAuth.instance.currentUser!.reload();

    setState(() {
      isEmailVerified = FirebaseAuth.instance.currentUser!.emailVerified;
    });

    if (isEmailVerified) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user['id'])
          .update({'isEmailVerified': true});
      timer?.cancel();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Enail verification successfull'),
        ),
      );
    }
  }

  Future<void> launchWhatsApp({required String phone, String? message}) async {
    // Encode the message if provided
    final text = message != null ? '&text=${Uri.encodeComponent(message)}' : '';
    final url = 'whatsapp://send?phone=$phone$text';

    final Uri whatsappUri = Uri.parse(url);

    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri);
    } else {
      // WhatsApp is not installed
      throw 'Could not launch WhatsApp. Make sure it is installed.';
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeCubit = context.watch<ThemeCubit>();
    bool isDarkMode = themeCubit.isDarkMode;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section with Profile Info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        child: Text(
                          widget.user['displayName'][0],
                          style: const TextStyle(
                            color: Color(0xFF8B5CF6),
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.user['displayName'],
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.user['email'] ?? '',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (!isEmailVerified)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Email not verified!',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                sendVerificationEmail();
                              },
                              child: const Text(
                                'Send e-mail',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          height: 50,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            'A verification email has been sent to  ${widget.user['email']}. Check your inbox or spam',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Menu Options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildMenuSection(context, 'Account Settings', [
                    _buildMenuItem(
                      context,
                      Icons.category_outlined,
                      'Manage Service',
                      () {
                        if (!isEmailVerified) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: Colors.red,
                              showCloseIcon: true,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadiusGeometry.circular(10),
                              ),
                              content: const Text('Email not verified'),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ServiceRegistrationScreen(
                                userId: widget.user['id'],
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    _buildMenuItem(
                      context,
                      Icons.favorite_outline,
                      'My Favorites',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                FavoriteScreen(user: widget.user),
                          ),
                        );
                      },
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _buildMenuSection(context, 'Preferences', [
                    //_buildMenuItem(context, Icons.language, 'Language', () {}),
                    _buildMenuItem(
                      context,
                      Icons.dark_mode_outlined,
                      'Dark Mode',
                      () {},
                      trailing: Switch(
                        value: isDarkMode,
                        onChanged: (value) {
                          themeCubit.toggleTheme();
                        },
                        activeThumbColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _buildMenuSection(context, 'Support', [
                    _buildMenuItem(
                      context,
                      Icons.help_outline,
                      'Help & Support',
                      () async{
                        var contact = '233244038837';
                        var text = 'Hello Support team. I need assistance with my account';
                        

                        try {
                          await launchWhatsApp(
                            phone: contact,
                            message: text,
                          );
                        } catch (e) {
                          // Show a snackbar or dialog
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(
                            SnackBar(
                              content: Text(
                                'WhatsApp not installed',
                              ),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadiusGeometry.circular(
                                      10,
                                    ),
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    _buildMenuItem(
                      context, Icons.info_outline, 'About', () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                TimelyLandingPage(),
                          ),
                        );
                    }),
                  ]),

                  const SizedBox(height: 16),
                  _buildMenuSection(context, 'Legal', [
                    _buildMenuItem(
                      context,
                      Icons.policy_outlined,
                      'Privacy Policy',
                      () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()));
                      },
                    ),
                    _buildMenuItem(
                      context, 
                      Icons.domain_verification, 
                      'Terms & Conditions', () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                TermsAndConditionsPage(),
                          ),
                        );
                    }),
                  ]),

                  const SizedBox(height: 24),

                  GestureDetector(
                    onTap: _showLogoutDialog,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.logout, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'Logout',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Confirm Logout',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No, Stay Logged In'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AuthCubit>().signOut();
              Navigator.of(context).pop();
              context.go('/app');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Logged out successfully'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusGeometry.circular(10),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, title, List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          ...items,
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap, {
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.withOpacity(0.1)),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            trailing ??
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
          ],
        ),
      ),
    );
  }
}
