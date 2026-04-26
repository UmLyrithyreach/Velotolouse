import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:velotolouse/data/repositories/bike/bike_repository.dart';
import 'package:velotolouse/data/repositories/booking/booking_repository.dart';
import 'package:velotolouse/data/repositories/trip/trip_repository.dart';
import 'package:velotolouse/data/repositories/user/user_repository.dart';
import 'package:velotolouse/provider/bike_provider.dart';
import 'package:velotolouse/provider/booking_provider.dart';
import 'package:velotolouse/provider/trip_provider.dart';
import 'package:velotolouse/provider/user_provider.dart';
import 'package:velotolouse/ui/screen/auth/view/login_screen.dart';
import 'package:velotolouse/ui/screen/booking/view_model/booking_viewmodel.dart';
import 'package:velotolouse/ui/screen/map/view_model/map_viewmodel.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // Register all providers with their repositories injected
      providers: [
        ChangeNotifierProvider(
          create: (_) => UserProvider(FirebaseUserRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) => BikeProvider(BikeRepositoryFirebase()),
        ),
        ChangeNotifierProvider(
          create: (_) => MapViewModel(BikeRepositoryFirebase()),
        ),
        ChangeNotifierProvider(
          create: (_) => BookingProvider(FirebaseBookingRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) => TripProvider(FirebaseTripRepository()),
        ),
        ChangeNotifierProvider(
          create: (context) => BookingViewModel(
            bookingProvider: context.read<BookingProvider>(),
            tripProvider: context.read<TripProvider>(),
            userProvider: context.read<UserProvider>(),
            mapViewModel: context.read<MapViewModel>(),
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'VeloToulouse',
        theme: ThemeData(
          colorSchemeSeed: Colors.blue,
          useMaterial3: true,
        ),
        // Start on the login screen
        home: const LoginScreen(),
      ),
    );
  }
}
