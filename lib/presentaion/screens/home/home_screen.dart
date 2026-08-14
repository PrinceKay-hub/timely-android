
import 'package:booking/core/services/upgrader_service.dart';
import 'package:booking/presentaion/connectivity/cubit/connectivity_cubit.dart';
import 'package:booking/presentaion/connectivity/cubit/connectivity_state.dart';
import 'package:booking/presentaion/provider/cubit/service_data/service_data_cubit.dart';
import 'package:booking/presentaion/screens/home/cubit_home/home_cubit.dart';
import 'package:booking/presentaion/screens/home/widget/categories_section.dart';
import 'package:booking/presentaion/screens/home/widget/modern_app_bar.dart';
import 'package:booking/presentaion/screens/home/widget/recommended_section.dart';
import 'package:booking/presentaion/screens/home/widget/special_offers_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    loadRecommendedServices();
  }

  Future<void> _initHome() async {
    final homeCubit = context.read<HomeCubit>();
    // Load categories
    homeCubit.loadCategories();
    // Get current location
    homeCubit.updateLocation();
  }

  Future<void> loadRecommendedServices() async {
    final serviceDataCubit = context.read<ServiceDataCubit>();
    if (serviceDataCubit.state is! ServiceDataLoaded) {
      await serviceDataCubit.fetchServiceData();
    } else {
      return;
    }
  }


  Future<void> onRefresh() async {
    context.read<ServiceDataCubit>().fetchServiceData();
    Future.delayed(Duration(milliseconds: 2));
  }

  final upgrader = Upgrader(
  debugLogging: true,
  storeController: UpgraderStoreController(
    onAndroid: () => BackendUpgraderStore(
      platformKey: 'android',
      manifestUrl: 'https://raw.githubusercontent.com/PrinceKay-hub/timely-android/main/app-version.json',
    ),
    oniOS: () => BackendUpgraderStore(
      platformKey: 'ios',
      manifestUrl: 'https://raw.githubusercontent.com/PrinceKay-hub/timely-android/main/app-version.json',
    ),
  ),
);

  @override
  Widget build(BuildContext context) {
    super.build(context); 
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
        }
      },
      child: UpgradeAlert(
        upgrader: upgrader,
        child: RefreshIndicator(
          onRefresh: onRefresh,
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
                      RecommendedSection(),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
