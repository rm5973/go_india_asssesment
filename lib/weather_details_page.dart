import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Weather Details'),
        backgroundColor: Colors.black,
      ),
      body: GestureDetector(
        onVerticalDragUpdate: (details) {
          if (details.primaryDelta! > 5.0) {
            // Perform refresh action here
            // You can fetch data again or reset state
          }
        },
        child: FutureBuilder(
          future: _controller.forward(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(),
              );
            } else {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _controller,
                  curve: Curves.easeInOut,
                )),
                child: Container(
                  color: Colors.transparent,
                  child: SingleChildScrollView(
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  for (int i = 0;
                                      i < recentCities.length;
                                      i += 2)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Expanded(
                                            child:
                                                _buildCard(recentCities[i], i),
                                          ),
                                          if (i + 1 < recentCities.length)
                                            Expanded(
                                              child: _buildCard(
                                                  recentCities[i + 1], i + 1),
                                            ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (expandedCardIndex != null)
                          Positioned.fill(
                            child: Center(
                              child: _buildExpandedCard(
                                  recentCities[expandedCardIndex!]),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
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
        padding: EdgeInsets.all(16.0),
        child: Row(
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
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
    );
  }
}
