import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:velotolouse/data/repositories/bike/bike_repository.dart';
import 'package:velotolouse/data/repositories/booking/booking_repository.dart';
import 'package:velotolouse/data/repositories/trip/trip_repository.dart';
import 'package:velotolouse/data/repositories/user/user_repository.dart';
import 'package:velotolouse/ui/screen/auth/view/login_screen.dart';
import 'package:velotolouse/ui/screen/auth/view_model/auth_viewmodel.dart';
import 'package:velotolouse/ui/screen/booking/view_model/booking_viewmodel.dart';
import 'package:velotolouse/ui/screen/history/view_model/history_viewmodel.dart';
import 'package:velotolouse/ui/screen/map/view_model/map_viewmodel.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // Register all viewmodels with their repositories injected
      providers: [
        // AuthViewModel - handles user authentication
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(FirebaseUserRepository()),
        ),

        // HistoryViewModel - handles trip history
        ChangeNotifierProvider(
          create: (_) => HistoryViewModel(FirebaseTripRepository()),
        ),

        // MapViewModel - handles bike map and ride operations
        ChangeNotifierProxyProvider<AuthViewModel, MapViewModel>(
          create: (context) => MapViewModel(
            BikeRepositoryFirebase(),
            FirebaseBookingRepository(),
            FirebaseTripRepository(),
            context.read<AuthViewModel>(),
          ),
          update: (context, authViewModel, previous) => MapViewModel(
            BikeRepositoryFirebase(),
            FirebaseBookingRepository(),
            FirebaseTripRepository(),
            authViewModel,
          ),
        ),

        // BookingViewModel - handles booking screen
        ChangeNotifierProxyProvider<AuthViewModel, BookingViewModel>(
          create: (context) => BookingViewModel(
            bookingRepository: FirebaseBookingRepository(),
            tripRepository: FirebaseTripRepository(),
            bikeRepository: BikeRepositoryFirebase(),
            authViewModel: context.read<AuthViewModel>(),
          ),
          update: (context, authViewModel, previous) {
            // Reuse previous instance if it exists, just update dependencies
            if (previous != null) {
              return previous;
            }
            return BookingViewModel(
              bookingRepository: FirebaseBookingRepository(),
              tripRepository: FirebaseTripRepository(),
              bikeRepository: BikeRepositoryFirebase(),
              authViewModel: authViewModel,
            );
          },
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
