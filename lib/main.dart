import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'weather_service.dart';
import 'weather_details_page.dart'; // Import the new file

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: Size(375, 812), // Adjust based on your design
      builder: (context, child) => MaterialApp(
        title: 'Weather App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: WeatherHomePage(),
      ),
    );
  }
}

class WeatherHomePage extends StatefulWidget {
  @override
  _WeatherHomePageState createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  final TextEditingController _controller = TextEditingController();
  final WeatherService _weatherService = WeatherService();
  Map<String, dynamic>? _weatherData;
  bool _isLoading = false;
  String? _errorMessage;
  LatLng? _cityLocation;
  LatLng? _currentLocation;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    final location = Location();

    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    final _locationData = await location.getLocation();
    setState(() {
      _currentLocation =
          LatLng(_locationData.latitude!, _locationData.longitude!);
    });
  }

  Future<void> _searchWeather() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final weatherData = await _weatherService.fetchWeather(_controller.text);
      final lat = weatherData['coord']['lat'];
      final lon = weatherData['coord']['lon'];
      final newLocation = LatLng(lat, lon);

      // Perform step-by-step animation from current location to new location
      _animateCameraToLocation(_currentLocation, newLocation, () async {
        setState(() {
          _weatherData = weatherData;
          _cityLocation = newLocation;
          _currentLocation =
              newLocation; // Update current location after search
          _isLoading = false;
        });

        // Wait for 5 seconds before navigating to WeatherDetailsPage
        await Future.delayed(Duration(seconds: 1));

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WeatherDetailsPage(weatherData: weatherData),
          ),
        );
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _animateCameraToLocation(LatLng? startLocation, LatLng endLocation,
      VoidCallback onAnimationComplete) {
    if (startLocation == null || _mapController == null) return;

    const steps = 10; // Number of steps for animation
    final startLat = startLocation.latitude;
    final startLng = startLocation.longitude;
    final endLat = endLocation.latitude;
    final endLng = endLocation.longitude;

    // Calculate step size
    final latStep = (endLat - startLat) / steps;
    final lngStep = (endLng - startLng) / steps;

    // Start animating camera
    Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (timer.tick > steps) {
        timer.cancel();
        onAnimationComplete(); // Call the callback after animation completes
        return;
      }

      final lat = startLat + latStep * timer.tick;
      final lng = startLng + lngStep * timer.tick;
      final position = LatLng(lat, lng);

      _mapController!.animateCamera(CameraUpdate.newLatLng(position));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Weather App'),
        backgroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          // Google Map displaying city location
          _currentLocation != null
              ? GoogleMap(
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  initialCameraPosition: CameraPosition(
                    target: _currentLocation!,
                    zoom: 10,
                  ),
                  markers: _cityLocation != null
                      ? {
                          Marker(
                            markerId: MarkerId('cityLocation'),
                            position: _cityLocation!,
                          ),
                        }
                      : {},
                )
              : Center(child: CircularProgressIndicator()),
          // Semi-transparent overlay
          Container(
            color: Colors.black.withOpacity(0.6),
          ),
          // Main content
          Positioned(
            top: kToolbarHeight + 16.0, // Adjust the top position as needed
            left: 16.0,
            right: 16.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Text field for city name
                Container(
                  constraints: BoxConstraints(
                      maxWidth: 600.w), // Max width for responsiveness
                  child: TextField(
                    controller: _controller,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Enter city name',
                      labelStyle: TextStyle(color: Colors.white),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.search, color: Colors.white),
                        onPressed: _searchWeather,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                if (_isLoading)
                  Center(
                    child: SizedBox(
                      height: 48.0, // Match the size of the menu icon
                      width: 48.0, // Match the size of the menu icon
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    ),
                  ),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red, fontSize: 14.sp),
                    ),
                  ),
                SizedBox(height: 16.h),
                // Menu icon below the search bar, hovering over the map
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.withOpacity(0.7),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.menu, color: Colors.white),
                    onPressed: () {
                      // Navigate to WeatherDetailsPage on menu button press
                      if (_weatherData != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                WeatherDetailsPage(weatherData: _weatherData!),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
