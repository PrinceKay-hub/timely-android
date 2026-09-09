
import 'package:booking/core/services/upgrader_service.dart';
import 'package:booking/presentaion/connectivity/cubit/connectivity_cubit.dart';
import 'package:booking/presentaion/connectivity/cubit/connectivity_state.dart';
import 'package:booking/presentaion/provider/cubit/service_data/service_data_cubit.dart';
import 'package:booking/presentaion/screens/home/cubit_home/home_cubit.dart';
import 'package:booking/presentaion/screens/home/cubit_home/near_you_cubit.dart';
import 'package:booking/presentaion/screens/home/cubit_home/top_rated_cubit.dart';
import 'package:booking/presentaion/screens/home/cubit_home/new_on_timely_cubit.dart';
import 'package:booking/presentaion/screens/home/widget/categories_section.dart';
import 'package:booking/presentaion/screens/home/widget/home_extra_sections.dart';
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

  late final ScrollController _scrollController;
  late final NearYouCubit _nearYouCubit;
  late final TopRatedCubit _topRatedCubit;
  late final NewOnTimelyCubit _newOnTimelyCubit;

  @override
  void initState() {
    super.initState();

    // Reuse the repository instance already injected into
    // ServiceDataCubit — avoids touching your DI setup.
    final repo = context.read<ServiceDataCubit>().serviceRepository;

    _nearYouCubit = NearYouCubit(repo);
    _topRatedCubit = TopRatedCubit(repo)..loadTopRated();
    _newOnTimelyCubit = NewOnTimelyCubit(repo)..loadNew();

    _scrollController = ScrollController()..addListener(_onScroll);

    _initHome();
    loadRecommendedServices();

    _tryLoadNearby(context.read<HomeCubit>().state.location);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _nearYouCubit.close();
    _topRatedCubit.close();
    _newOnTimelyCubit.close();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 400;
    if (_scrollController.position.pixels >= threshold) {
      context.read<ServiceDataCubit>().fetchNextPage();
    }
  }

  void _tryLoadNearby(String location) {
    final parts = location.split(',');
    if (parts.length != 2) return;
    final lat = double.tryParse(parts[0]);
    final lng = double.tryParse(parts[1]);
    if (lat != null && lng != null) {
      _nearYouCubit.loadNearby(latitude: lat, longitude: lng);
    }
  }

  Future<void> _initHome() async {
    final homeCubit = context.read<HomeCubit>();
    homeCubit.loadCategories();
    homeCubit.updateLocation();
  }

  Future<void> loadRecommendedServices() async {
    final serviceDataCubit = context.read<ServiceDataCubit>();
    if (serviceDataCubit.state is! ServiceDataLoaded) {
      await serviceDataCubit.fetchServiceData();
    }
  }

  Future<void> onRefresh() async {
    context.read<ServiceDataCubit>().fetchServiceData();
    _topRatedCubit.loadTopRated();
    _newOnTimelyCubit.loadNew();
    // Near You re-fires via the location listener below.
  }

  final upgrader = Upgrader(
    storeController: UpgraderStoreController(
      onAndroid: () => BackendUpgraderStore(
        platformKey: 'android',
        manifestUrl:
            'https://raw.githubusercontent.com/PrinceKay-hub/timely-android/main/app-version.json',
      ),
      oniOS: () => BackendUpgraderStore(
        platformKey: 'ios',
        manifestUrl:
            'https://raw.githubusercontent.com/PrinceKay-hub/timely-android/main/app-version.json',
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _nearYouCubit),
        BlocProvider.value(value: _topRatedCubit),
        BlocProvider.value(value: _newOnTimelyCubit),
      ],
      child: BlocListener<HomeCubit, HomeState>(
        listenWhen: (prev, curr) =>
            prev.locationError != curr.locationError ||
            prev.location != curr.location,
        listener: (context, state) {
          if (state.locationError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Enable location to see nearby services.')),
            );
          }
          // HomeState.location is a "lat,lng" string (see setLocation
          // in HomeCubit.updateLocation()).
          final parts = state.location.split(',');
          if (parts.length == 2) {
            final lat = double.tryParse(parts[0]);
            final lng = double.tryParse(parts[1]);
            if (lat != null && lng != null) {
              _nearYouCubit.loadNearby(latitude: lat, longitude: lng);
            }
          }
        },
        child: BlocListener<ConnectivityCubit, ConnectivityState>(
          listener: (context, state) {
            if (state.status == ConnectivityStatus.offline) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text('You are offline. Some features may be limited.'),
                  duration: Duration(days: 1),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
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
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    ModernAppBar(user: widget.user),
                    SliverPadding(
                      padding: EdgeInsets.zero,
                      sliver: SliverList(
                        delegate: SliverChildListDelegate.fixed([
                          SpecialOffersCard(user: widget.user),
                          SizedBox(height: 15),
                          CategoriesSection(user: widget.user),
                          SizedBox(height: 15),
                          const NearYouSection(),
                          const TopRatedSection(),
                          const NewOnTimelySection(),
                          const RecommendedSection(), // paginated Top services
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}