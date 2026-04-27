import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:velotolouse/model/bike/bike.dart';
import 'package:velotolouse/ui/screen/auth/view/login_screen.dart';
import 'package:velotolouse/ui/screen/auth/view_model/auth_viewmodel.dart';
import 'package:velotolouse/ui/screen/booking/view/booking_screen.dart';
import 'package:velotolouse/ui/screen/history/view/history_screen.dart';
import 'package:velotolouse/ui/screen/map/view_model/map_viewmodel.dart';
import 'package:velotolouse/ui/widgets/primary_button.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with WidgetsBindingObserver {
  // Controller for the search bar
  final _searchController = TextEditingController();

  // Search query text (used to filter bikes)
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future(() => context.read<MapViewModel>().fetchAllBikes());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh bikes when app comes back to foreground
      context.read<MapViewModel>().fetchAllBikes();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch providers so UI rebuilds when state changes
    final mapViewModel = context.watch<MapViewModel>();
    final authViewModel = context.watch<AuthViewModel>();

    final actionMessage = mapViewModel.consumeActionMessage();
    if (actionMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(actionMessage)));
      });
    }

    final endTripResult = mapViewModel.consumeLastEndTripResult();
    if (endTripResult != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!context.mounted) return;
        await showDialog<void>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Ride Completed'),
              content: Text(
                'Distance: ${endTripResult.distanceKm.toStringAsFixed(2)} km\n'
                'Price: \$${endTripResult.price.toStringAsFixed(2)}',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      });
    }

    // Get filtered list of bikes from ViewModel
    final filteredBikes = mapViewModel.filterBikesByName(_searchQuery);

    return Scaffold(
      appBar: AppBar(
        title: const Text('VeloToulouse'),
        automaticallyImplyLeading: false, // No back button
        actions: [
          // History button — navigates to trip history
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Trip History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
            },
          ),
          // Logout button
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              authViewModel.logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // The map widget showing Phnom Penh
          FlutterMap(
            options: MapOptions(
              // Center on Phnom Penh, Cambodia
              initialCenter: LatLng(11.5564, 104.9282),
              initialZoom: 13.0,
            ),
            children: [
              // OpenStreetMap tile layer (free, no API key needed)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.velotolouse.app',
              ),

              // Bike markers on the map
              MarkerLayer(
                markers: filteredBikes.map((bike) {
                  return Marker(
                    point: LatLng(bike.latitude, bike.longitude),
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () {
                        // Show bike info when marker is tapped
                        _showBikeInfo(context, bike);
                      },
                      child: Icon(
                        Icons.location_on,
                        color: bike.status == 'available'
                            ? Colors.green
                            : Colors.red,
                        size: 30,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // Search bar widget on top of the map
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search bikes by name...',
                  prefixIcon: const Icon(Icons.search),
                  // Clear button when text is entered
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                onChanged: (value) {
                  // Update the search query when text changes
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
          ),

          // Show loading indicator while fetching bikes
          if (mapViewModel.isLoading)
            const Center(child: CircularProgressIndicator()),

          // Show error message if something went wrong
          if (mapViewModel.error != null)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  mapViewModel.error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Show a bottom sheet with bike details when a marker is tapped
  void _showBikeInfo(BuildContext context, Bike bike) {
    final authViewModel = context.read<AuthViewModel>();
    final mapViewModel = context.read<MapViewModel>();
    final currentUser = authViewModel.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please login first')));
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bike name
              Text(
                bike.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Bike status
              Row(
                children: [
                  const Text('Status: '),
                  Text(
                    bike.status,
                    style: TextStyle(
                      color: bike.status == 'available'
                          ? Colors.green
                          : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (mapViewModel.canBookBike(
                bike: bike,
                authViewModel: authViewModel,
              ))
                PrimaryButton(
                  text: 'Book Bike',
                  onPressed: () async {
                    Navigator.pop(ctx);
                    // Navigate to BookingScreen and refresh bikes when returning
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookingScreen(bike: bike),
                      ),
                    );
                    // Refresh bikes after returning from booking screen
                    if (context.mounted) {
                      context.read<MapViewModel>().fetchAllBikes();
                    }
                  },
                ),

              const SizedBox(height: 8),

              OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }
}
