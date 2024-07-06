import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'weather_service.dart';
import 'weather_details_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: Size(375, 812),
      builder: (context, child) => MaterialApp(
        title: "Weather App",
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        debugShowCheckedModeBanner: false,
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
    });

    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog(
          "No internet connection. Please connect to the internet and try again.");
      return;
    }

    try {
      final weatherData = await _weatherService.fetchWeather(_controller.text);
      final lat = weatherData['coord']['lat'];
      final lon = weatherData['coord']['lon'];
      final newLocation = LatLng(lat, lon);

      _animateCameraToLocation(_currentLocation, newLocation, () async {
        setState(() {
          _weatherData = weatherData;
          _cityLocation = newLocation;
          _currentLocation = newLocation;
          _isLoading = false;
        });

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
        _isLoading = false;
      });
      _showErrorDialog("Couldn't find the city. Please try again.");
    }
  }

  void _animateCameraToLocation(LatLng? startLocation, LatLng endLocation,
      VoidCallback onAnimationComplete) {
    if (startLocation == null || _mapController == null) return;

    const steps = 10;
    final startLat = startLocation.latitude;
    final startLng = startLocation.longitude;
    final endLat = endLocation.latitude;
    final endLng = endLocation.longitude;

    final latStep = (endLat - startLat) / steps;
    final lngStep = (endLng - startLng) / steps;

    Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (timer.tick > steps) {
        timer.cancel();
        onAnimationComplete();
        return;
      }

      final lat = startLat + latStep * timer.tick;
      final lng = startLng + lngStep * timer.tick;
      final position = LatLng(lat, lng);

      _mapController!.animateCamera(CameraUpdate.newLatLng(position));
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
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
          Container(
            color: Colors.black.withOpacity(0.6),
          ),
          Positioned(
            top: kToolbarHeight + 16.0,
            left: 16.0,
            right: 16.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  constraints: BoxConstraints(maxWidth: 600.w),
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
                      height: 48.0,
                      width: 48.0,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    ),
                  ),
                SizedBox(height: 16.h),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.withOpacity(0.7),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.menu, color: Colors.white),
                    onPressed: () {
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
