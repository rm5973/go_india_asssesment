Weather App

Weather App is a Flutter application that displays weather information for multiple cities and allows users to view detailed weather data for each city.

Features:-
Recent Cities: Display a list of recently viewed cities with their current weather.
Weather Details: View detailed weather information including temperature, description, humidity, and wind speed.
City Management: Add and remove cities from the list of recent cities.
Refresh Data: Swipe down to refresh weather data for the current city.


Installation

Clone the repository:
Copy the code and paste in it in the powershell terminal for windows10 & cmd terminal for windows11

git clone https://github.com/rm5973/go_india_asssesment.git


Navigate into the project directory:
Copy code in the cmd terminal or powershell to navigate to weather_app directory

cd weather_app


Install dependencies:
Copy code and paste it in the cmd terminal of the weather_app folder to install all the dependencies 

flutter pub get


Run the app:
Copy code to execute the flutter project .

flutter run


Usage

Upon launching the app will check the internet contectivity status, then  the app will make sure to check the user internet conectivity,then you will see the map and a search bar to search for the city's weather.
The app redirects to a new page displaying weather information after entering a particular city name.
On the landing page, you can also retrieve information about previously searched cities' history.
Use the refresh and delete buttons on the expanded weather card to update or remove the city from the list.

Dependencies

shared_preferences: For storing recent cities locally.
http: For making HTTP requests to fetch weather data from an API.
flutter_screenutil: For responsive UI design based on device screen size.
flutter_typeahead: Provides a typeahead (autocomplete) widget for Flutter applications.
google_maps_flutter:Integrates Google Maps capabilities into Flutter applications.
location: Provides access to the device's location services.
google_maps_flutter_web:Extends Google Maps functionality specifically for web applications in Flutter.


Contributing

Contributions are welcome! Please fork the repository and create a pull request with your improvements.

Fork the project

Create your feature branch (git checkout -b feature/AmazingFeature)
Commit your changes (git commit -m 'Add some AmazingFeature')
Push to the branch (git push origin feature/AmazingFeature)
Open a pull request


