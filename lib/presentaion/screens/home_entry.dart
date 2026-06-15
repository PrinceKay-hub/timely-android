// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:booking/domain/entities/user_entity.dart';
import 'package:booking/presentaion/common/pages/loading_screen.dart';
import 'package:booking/presentaion/screens/favorite/favorite_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:booking/presentaion/screens/appointments/appointments_screen.dart';
import 'package:booking/presentaion/screens/home/home_screen.dart';
import 'package:booking/presentaion/screens/profile/profile_screen.dart';
import 'package:booking/presentaion/user/cubit/user_cubit.dart';

class HomeEntry extends StatefulWidget {
  final UserEntity? user;
  const HomeEntry({
    super.key,
    this.user,
  });

  @override
  State<HomeEntry> createState() => _HomeEntryState();
}

class _HomeEntryState extends State<HomeEntry> {
  late final userCubit = context.read<UserCubit>();
  
  var currentContentIndex = 0;
  Map<String, dynamic> user = {};


  @override
  void initState() {
    fetchHomeData();
    super.initState();
  }

  fetchHomeData() async {
    userCubit.loadUser();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserCubit, UserState>(
      builder: (context, state) {
        if (state is UserLoading) {
          return LoadingScreen();
        }

         if (state is UserError) {
          return Scaffold(
            body: Center(child: Text('Error loading user: ${state.message}')),
          );
        }

         if (state is UserLoaded) {
          return Scaffold(
            body: buildAppBodyContent(currentContentIndex, state.user),
            bottomNavigationBar: buildBottomNavigation(),
          );
        }

         // Default fallback UI
         return Scaffold(
          body: Center(child: Text('No user data available')),
        );
        
      },
    );
  }

  Widget buildAppBodyContent(int index, Map<String, dynamic> user ) {
    switch (index) {
      case 0:
        return HomeScreen(user: user);
      case 1:
        return FavoriteScreen(user: user);

      case 2:
        return AppointmentsScreen(user: user);

      case 3:
        return ProfileScreen(user: user);

      default:
        return const HomeEntry();
    }
  }

  Widget buildBottomNavigation() {
    return BottomNavigationBar(
      //backgroundColor: const Color(0xFF2D2D2D),
      type: BottomNavigationBarType.fixed,
      currentIndex: currentContentIndex,
      selectedItemColor: Color.fromARGB(255, 95, 46, 209),
      unselectedItemColor: Colors.grey[600],
      showSelectedLabels: true,
      showUnselectedLabels: true,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      onTap: (index) {
        setState(() {
          currentContentIndex = index;
        });
      },
      items: const [
        BottomNavigationBarItem(
          icon: FaIcon(FontAwesomeIcons.house),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: FaIcon(FontAwesomeIcons.heart),
          label: 'Favorites',
        ),
        BottomNavigationBarItem(
          icon: FaIcon(FontAwesomeIcons.calendar),
          label: 'Appointments',
        ),
        BottomNavigationBarItem(
          icon: FaIcon(FontAwesomeIcons.user),
          label: 'Profile',
        ),
      ],
    );
  }
}
