import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherDetailsPage extends StatefulWidget {
  final Map<String, dynamic> weatherData;

  const WeatherDetailsPage({Key? key, required this.weatherData})
      : super(key: key);

  @override
  _WeatherDetailsPageState createState() => _WeatherDetailsPageState();
}

class _WeatherDetailsPageState extends State<WeatherDetailsPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> recentCities = [];
  int? expandedCardIndex;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _loadRecentCities();
  }

  Future<void> _loadRecentCities() async {
    await Future.delayed(Duration(milliseconds: 100)); // Delay for animation
    final prefs = await SharedPreferences.getInstance();
    final citiesString = prefs.getString('recentCities') ?? '[]';
    final List<dynamic> citiesJson = json.decode(citiesString);
    setState(() {
      recentCities =
          citiesJson.map((json) => json as Map<String, dynamic>).toList();
    });
    _addCity(widget.weatherData);
  }

  Future<void> _addCity(Map<String, dynamic> weatherData) async {
    setState(() {
      recentCities.removeWhere((city) => city['name'] == weatherData['name']);
      recentCities.insert(0, weatherData); // Add new city to the beginning
    });
    final prefs = await SharedPreferences.getInstance();
    final citiesJson = json.encode(recentCities);
    prefs.setString('recentCities', citiesJson);
  }

  Future<void> _fetchWeatherData(String cityName) async {
    // Replace with your actual API endpoint and key
    final apiKey = '65b642fa408fba9f53d63cd25b1d1dcc';
    final apiUrl =
        'https://api.openweathermap.org/data/2.5/weather?q=$cityName&appid=$apiKey&units=metric';

    final response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      final weatherData = json.decode(response.body);
      setState(() {
        recentCities[expandedCardIndex!] = weatherData;
      });
    } else {
      // Handle the error
      print('Failed to fetch weather data');
    }
  }

  Future<void> _removeCity(int index) async {
    setState(() {
      recentCities.removeAt(index);
    });
    final prefs = await SharedPreferences.getInstance();
    final citiesJson = json.encode(recentCities);
    prefs.setString('recentCities', citiesJson);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('City removed from the list.'),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Weather Details',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Color(0xFF7AC0E9),
      ),
      body: GestureDetector(
        onVerticalDragUpdate: (details) {
          if (details.primaryDelta! > 5.0) {
            // Perform refresh action here
            // You can fetch data again or reset state
          }
        },
        child: Stack(
          children: [
            _buildBackgroundGradient(), // Background gradient
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _buildRecentCitiesCards(),
              ),
            ),
            if (expandedCardIndex != null)
              Positioned.fill(
                child: Center(
                  child: _buildExpandedCard(recentCities[expandedCardIndex!]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundGradient() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.55, 1.0], // Adjust stops here
          colors: [
            Color(0xFF87CEEB), // Sky blue
            Color(0xFFF4A460), // Sandy brown
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRecentCitiesCards() {
    List<Widget> cards = [];

    for (int i = 0; i < recentCities.length; i += 2) {
      Widget firstCard = Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: _buildCard(recentCities[i], i),
        ),
      );

      Widget secondCard;
      if (i + 1 < recentCities.length) {
        secondCard = Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: _buildCard(recentCities[i + 1], i + 1),
          ),
        );
      } else {
        // If there's only one card left, create an empty placeholder for alignment
        secondCard = Expanded(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.5 -
                16.0, // Adjust width as needed
          ),
        );
      }

      cards.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [firstCard, secondCard],
          ),
        ),
      );
    }

    return cards;
  }

  Widget _buildCard(Map<String, dynamic> cityWeather, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (expandedCardIndex == index) {
            expandedCardIndex = null;
          } else {
            expandedCardIndex = index;
          }
        });
      },
      child: Stack(
        children: [
          Opacity(
            opacity: 0.5,
            child: Container(
              height: 100.0,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8.0,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: 100.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.0),
            ),
            padding: EdgeInsets.all(16.0),
            child: Row(
              children: [
                Image.network(
                  'http://openweathermap.org/img/wn/${cityWeather['weather'][0]['icon']}@2x.png',
                  width: 50.0,
                  height: 50.0,
                ),
                SizedBox(width: 10.0),
                Flexible(
                  child: Text(
                    cityWeather['name'],
                    style: TextStyle(fontSize: 20.0),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedCard(Map<String, dynamic> cityWeather) {
    return GestureDetector(
      onTap: () {
        setState(() {
          expandedCardIndex = null;
        });
      },
      child: Stack(
        children: [
          Opacity(
            opacity: 0.5,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              height: 240.0,
              width: MediaQuery.of(context).size.width * 0.9,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8.0,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
            ),
          ),
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            height: 240.0,
            width: MediaQuery.of(context).size.width * 0.9,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.0),
            ),
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Image.network(
                          'http://openweathermap.org/img/wn/${cityWeather['weather'][0]['icon']}@2x.png',
                          width: 50.0,
                          height: 50.0,
                        ),
                        SizedBox(width: 10.0),
                        Text(
                          cityWeather['name'],
                          style: TextStyle(fontSize: 20.0),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.refresh, color: Colors.blue),
                          onPressed: () {
                            _fetchWeatherData(cityWeather['name']);
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _removeCity(expandedCardIndex!);
                            setState(() {
                              expandedCardIndex = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 10.0),
                Text(
                  'Temperature: ${cityWeather['main']['temp'].round()}°C',
                  style: TextStyle(fontSize: 16.0),
                ),
                Text(
                  'Description: ${cityWeather['weather'][0]['description']}',
                  style: TextStyle(fontSize: 16.0),
                ),
                Text(
                  'Humidity: ${cityWeather['main']['humidity']}%',
                  style: TextStyle(fontSize: 16.0),
                ),
                Text(
                  'Wind Speed: ${cityWeather['wind']['speed']} m/s',
                  style: TextStyle(fontSize: 16.0),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
