import 'package:booking/core/network/firebase_service.dart';
import 'package:booking/core/services/firebase_messaging_handler.dart';
import 'package:booking/core/services/local_notification_service.dart';
import 'package:booking/core/services/location_service.dart';
import 'package:booking/core/services/storage_service.dart';
import 'package:booking/core/theme/theme_app.dart';
import 'package:booking/data/repositories/auth_repository_impl.dart';
import 'package:booking/data/repositories/booking_repository_impl.dart';
import 'package:booking/data/repositories/category_repository.dart';
import 'package:booking/data/repositories/favorite_repositry_impl.dart';
import 'package:booking/data/repositories/location_repository_impl.dart';
import 'package:booking/data/repositories/review_repository_impl.dart';
import 'package:booking/data/repositories/search_repository_impl.dart';
import 'package:booking/data/repositories/service_repository_impl.dart';
import 'package:booking/data/repositories/user_repository_impl.dart';
import 'package:booking/firebase_options.dart';
import 'package:booking/presentaion/auth/cubit/auth_cubit.dart';
import 'package:booking/presentaion/booking/cubit/booking_cubit.dart';
import 'package:booking/presentaion/connectivity/cubit/connectivity_cubit.dart';
import 'package:booking/presentaion/provider/cubit/registration/service_registration_cubit.dart';
import 'package:booking/presentaion/provider/cubit/service_data/service_data_cubit.dart';
import 'package:booking/presentaion/provider/cubit/service_detail/service_detail_cubit.dart';
import 'package:booking/presentaion/provider/pages/portfolio/bloc/portfolio_bloc.dart';
import 'package:booking/presentaion/review/cubit/review_cubit.dart';
import 'package:booking/presentaion/screens/favorite/bloc/favorite_bloc.dart';
import 'package:booking/presentaion/screens/home/cubit/home_cubit.dart';
import 'package:booking/presentaion/screens/location/cubit/cubit/set_location_cubit.dart';
import 'package:booking/presentaion/screens/location/cubit/location_cubit.dart';
import 'package:booking/presentaion/screens/search/cubit/search_cubit.dart';
import 'package:booking/presentaion/theme/cubit/theme_cubit.dart';
import 'package:booking/presentaion/user/cubit/user_cubit.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPreferences.getInstance();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  final LocalNotificationService notificationService = LocalNotificationService();
  
  notificationService.initInfo();

  // Initialize Hive for Flutter
  await Hive.initFlutter();
  
  // Open a box (like opening a table)
  await Hive.openBox('myBox');

  // Enable the Android photo picker before using ImagePicker
  final ImagePickerPlatform imagePickerImplementation = ImagePickerPlatform.instance;
  if (imagePickerImplementation is ImagePickerAndroid) {
    imagePickerImplementation.useAndroidPhotoPicker = true;
  }

  await dotenv.load(fileName: ".env");

  runApp(MyApp(notificationService: notificationService));
}

class MyApp extends StatelessWidget {
  final LocalNotificationService notificationService;

  const MyApp({super.key, required this.notificationService});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (context) => FirebaseService()),
        RepositoryProvider(create: (context) => StorageService()),
        RepositoryProvider(
          create: (context) => AuthRepositoryImpl(
            firebaseService: context.read<FirebaseService>(),
          ),
        ),
        RepositoryProvider(
          create: (context) => ServiceRepositoryImpl(
            firebaseService: context.read<FirebaseService>(),
          ),
        ),
        RepositoryProvider(
          create: (context) => UserRepositoryImpl(
            firebaseService: context.read<FirebaseService>(),
            storageServices: context.read<StorageService>(),
          ),
        ),

        RepositoryProvider(create: (context) => BookingRepositoryImpl()),
        RepositoryProvider<LocalNotificationService>.value(
          value: notificationService,
        ),
        RepositoryProvider(create: (context) => ReviewRepositoryImpl(),),
        RepositoryProvider(create: (context) => LocationRepositoryImpl(),),
        RepositoryProvider(create: (context) => SearchRepositoryImpl(),),
        RepositoryProvider(create: (_) => FavoriteRepositryImpl()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => ThemeCubit()),
          BlocProvider(
            create: (context) =>
                AuthCubit(context.read<AuthRepositoryImpl>())
                  ..checkAuthStatus(),
          ),
          BlocProvider(
            create: (context) => UserCubit(context.read<UserRepositoryImpl>()),
          ),
          BlocProvider(
            create: (context) =>
                ServiceDataCubit(context.read<ServiceRepositoryImpl>()),
          ),
          BlocProvider(
            create: (context) => ServiceRegistrationCubit(
              serviceRepository: context.read<ServiceRepositoryImpl>(),
              userRepository: context.read<UserRepositoryImpl>(),
              storageService: context.read<StorageService>(),
            ),
          ),
          BlocProvider(
            create: (context) => BookingCubit(
              bookingRepository: context.read<BookingRepositoryImpl>(),
              userRepository: context.read<UserRepositoryImpl>(),
              notificationService: notificationService,
            ),
          ),
          BlocProvider(create: (context) => ReviewCubit(
            repositoryImpl: context.read<ReviewRepositoryImpl>(),
          ),),
          BlocProvider(create: (context) => LocationCubit(
            locationRepositoryImpl: context.read<LocationRepositoryImpl>(),
          ),),
          BlocProvider(create: (context) => SearchCubit(
            searchRepositoryImpl: context.read<SearchRepositoryImpl>()),),
          BlocProvider<SetLocationCubit>(create: (context) => SetLocationCubit(),),
          BlocProvider(
          create: (context) => FavoriteCubit(
            favoriteService: context.read<FavoriteRepositryImpl>(),
          )..loadFavorites(),
          ),
          BlocProvider(create: (context) => ServiceDetailCubit(context.read<ServiceRepositoryImpl>()),),
          BlocProvider(
            create: (context) => HomeCubit(
              categoryRepository: CategoryRepository(Hive.box('myBox')),
              locationService: LocationService(),
            ), ),
          BlocProvider(
            create: (context) => ConnectivityCubit(),
          ),
          BlocProvider(
          create: (context) => PortfolioCubit(),
        )
        ],
        child: const ThemeApp(),
      ),
    );
  }
}
