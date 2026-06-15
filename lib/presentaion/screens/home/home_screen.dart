
import 'package:booking/presentaion/auth/cubit/auth_cubit.dart';
import 'package:booking/presentaion/auth/cubit/auth_state.dart';
import 'package:booking/presentaion/connectivity/cubit/connectivity_cubit.dart';
import 'package:booking/presentaion/connectivity/cubit/connectivity_state.dart';
import 'package:booking/presentaion/provider/cubit/service_data/service_data_cubit.dart';
import 'package:booking/presentaion/screens/home/cubit/home_cubit.dart';
import 'package:booking/presentaion/screens/home/widget/categories_section.dart';
import 'package:booking/presentaion/screens/home/widget/modern_app_bar.dart';
import 'package:booking/presentaion/screens/home/widget/recommended_section.dart';
import 'package:booking/presentaion/screens/home/widget/special_offers_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:upgrader/upgrader.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initHome();
    _saveFCMToken();
  }

  Future<void> _initHome() async {
    final homeCubit = context.read<HomeCubit>();
    // Load categories
    homeCubit.loadCategories();
    // Get current location
    homeCubit.updateLocation();
    // Fetch service data (already done by ServiceDataCubit, but we can trigger if needed)
    context.read<ServiceDataCubit>().fetchServiceData();
  }

  Future<void> _saveFCMToken() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.user['id'])
            .set({'fcmToken': token}, SetOptions(merge: true));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return  BlocListener<ConnectivityCubit, ConnectivityState>(
      listener: (context, state) {
        if (state.status == ConnectivityStatus.offline) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You are offline. Some features may be limited.'),
              duration: Duration(days: 1),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        } else if (state.status == ConnectivityStatus.online) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          // Optionally refresh data
          context.read<ServiceDataCubit>().fetchServiceData();
        }
      },
      child: UpgradeAlert(
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.secondary,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // App bar
              ModernAppBar(user: widget.user),
              SliverPadding(
                padding: EdgeInsets.zero,
                sliver: SliverList(
                  delegate: SliverChildListDelegate.fixed([
                    SpecialOffersCard(user: widget.user),
                    CategoriesSection(user: widget.user),
                    RecommendedSection(user: widget.user),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
