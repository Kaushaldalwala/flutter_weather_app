// A widget is a small, standalone application or interactive element that provides specific information or functionality on a device or website
// dynamic keyword is used to declare the variables whose values are meant to be updated during the runtime
// The Scaffold widget in Flutter provides the basic visual structure for a Material Design application


import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;   // for request and response procedure
import 'package:lottie/lottie.dart'; // for getting the animations
import 'package:geolocator/geolocator.dart'; // for getting the location based service
import 'package:google_fonts/google_fonts.dart'; // for getting the types of the fonts  from google fonts
import 'package:flutter_dotenv/flutter_dotenv.dart'; // loads the enviornment file that stores  the enviornment object of the projects

const String apiKey = 'aff78e8562c7207e84ff596365f9405d'; // open weather api key

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // makes sure flutter is ready before running anything
  try {
    await dotenv.load(fileName: ".env");   // loads the .env file that contains API keys and other hidden values
  } catch (e) {
    print("No .env file found, using default API key"); //preventing from crash
  }
  runApp(const MyApp()); // starts the flutter app
}

class MyApp extends StatelessWidget { // main app widget that does not change
  const MyApp({super.key});  // constructor for the widget

  @override
  Widget build(BuildContext context) { // builds the UI of the app
    return MaterialApp(
      debugShowCheckedModeBanner: false, // hides the "debug" banner in the corner
      title: 'Weather App', //title of the app
      theme: ThemeData(
        brightness: Brightness.dark, //sets the theme of the app
        useMaterial3: true, // enables the material material 3
      ),
      home: const WeatherPage(),  //first page of the app
    );
  }
}


// Stateless Widget --> A Stateless Widget is static — it doesn’t change once it’s built.
// Stateful Widget -> A Stateful Widget is dynamic — it can change after it’s built.

class WeatherPage extends StatefulWidget { // creates the stateful widget named weather page
  const WeatherPage({super.key}); // constructor for weather page, uses the deafult key from the superclass

  //link the weather page widget witg it's state class (where the actual changes appear)
  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

// Define the State class for WeatherPage(logic of thw weather app)
class _WeatherPageState extends State<WeatherPage> {
  // define of the private variable
  // Necessary details of the page
  String _cityName = 'Loading...';
  String _temperature = '';
  String _mainCondition = '';
  String _feelsLike = '';
  String _humidity = '';
  String _windSpeed = '';
  bool _isLoading = true;
  String _errorMessage = '';

  // controller for the text input feild where user types the city name
  final TextEditingController _cityController = TextEditingController();
  // for the first instance of the class
  @override
  void initState() {
    super.initState(); // parent class is first instanciated
    _fetchWeather(); // fetch the weather data
  }
  // Function to fetch weather information
  Future<void> _fetchWeather() async {
    // Show loading indicator and clear previous errors
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      // check the location permission
      LocationPermission permission = await Geolocator.checkPermission();
      // If permission is denied, request it
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        // If still denied, throw an error
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }
      // tells that location permission is permantlt denied
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }
      // gets the location with higher accurancy
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // Fetch weather using the coordinates
      await _fetchWeatherByCoordinates(position.latitude, position.longitude);
    } catch (e) {
      // If any error occurs (permission denied or location fetch fails)
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to get your location. Please enter a city name.';
      });
    }
  }
  // Function to fetch weather data for a given city name
  Future<void> _fetchWeatherByCity(String cityName) async {
    // If the user didn't enter a city, show an error and stop
    if (cityName.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a city name.';
      });
      return; //exit
    }
    // Start loading and clear previous errors
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    // fetch the weather data from the api
    final String url =
        'https://api.openweathermap.org/data/2.5/weather?q=$cityName&appid=$apiKey&units=metric';

    try {
      // make the http get requests to fetch the weather data
      final response = await http.get(Uri.parse(url));
      // if the request is successful
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body); //parses the jsom
        _updateWeatherData(data); //updaate ui based on weather
      }
      // if city not found
      else if (response.statusCode == 404) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'City not found. Please check the spelling and try again.';
        });
      }
      // for other http error
      else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error: ${response.statusCode}. Please try again.';
        });
      }
    }
    // for any other type of the error
    catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to connect to the weather service. Check your internet connection.';
      });
    }
  }

  // Function to fetch weather data using GPS coordinates (latitude & longitude)
  Future<void> _fetchWeatherByCoordinates(double latitude, double longitude) async {
    // Build OpenWeather API URL with latitude, longitude, API key, and metric units
    final String url =
        'https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&appid=$apiKey&units=metric';

    // http error handling and resources fetching from
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        _updateWeatherData(data);
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load weather data for your location.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to connect to the weather service.';
      });
    }
  }
  // gets the weather data details and converts to string

  void _updateWeatherData(Map<String, dynamic> data) {
    setState(() {
      _cityName = data['name'];
      _temperature = data['main']['temp'].round().toString();
      _mainCondition = data['weather'][0]['main'].toLowerCase();
      _feelsLike = data['main']['feels_like'].round().toString();
      _humidity = data['main']['humidity'].toString();
      _windSpeed = data['wind']['speed'].round().toString();
      _isLoading = false;
    });
  }

  // loads the weather animations
  String _getWeatherAnimation(String? mainCondition) {
    if (mainCondition == null) {
      return 'assets/animations/loader.json';
    }
    switch (mainCondition.toLowerCase()) {
      case 'clouds':
        return 'assets/animations/cloudy.json';
      case 'mist':
        return 'assets/animations/mist.json';
      case 'fog':
        return 'assets/animations/Fog.json';
      case 'rain':
        return 'assets/animations/shower rain.json';
      case 'clear':
        return 'assets/animations/sunny.json';
      case 'snow':
        return 'assets/animations/snowfall.json';
      case 'thunderstorm':
        return 'assets/animations/thunderstrom.json';
      case 'haze':
        return 'assets/animations/haze.json';
      case 'smoke':
        return 'assets/animations/cloudy.json';
      case 'dust':
        return 'assets/animations/dust.json';
      case 'drizzle':
        return 'assets/animations/shower rain.json';
      default:
        return 'assets/animations/sunny.json';
    }
  }

  // for getting the icons based on the weather condition
  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clouds':
        return Icons.cloud;
      case 'rain':
      case 'drizzle':
        return Icons.water_drop;
      case 'clear':
        return Icons.wb_sunny;
      case 'snow':
        return Icons.ac_unit;
      case 'thunderstorm':
        return Icons.flash_on;
      case 'mist':
      case 'fog':
      case 'haze':
        return Icons.blur_on;
      default:
        return Icons.wb_cloudy;
    }
  }
  // to build function of small weather card details
  Widget _buildWeatherDetail({
    required IconData icon,
    required String label,
    required String value,
  //   to show icon and details
  }) {
    return Container(
      padding: const EdgeInsets.all(16), // adds spacing
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1), // create semi-transparent background
        borderRadius: BorderRadius.circular(12), //rounded corner
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // only takes the space that is needed
        children: [
          Icon(icon, color: Colors.white, size: 30), //show the icom
          const SizedBox(height: 8),
          Text(
            label, // show the text (such as humidity)
            style: GoogleFonts.poppins(
              color: Colors.white70, //slightly transparent
              fontSize: 14,
              fontWeight: FontWeight.w500, //medium font weights
            ),
          ),
          const SizedBox(height: 4), // small vertical spacing
          Text(
            value, //shows the values of text
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // helper function to show the wheather details
  Widget _buildLottieAnimation(String animationPath) {
    // creates the box for showing the animation
    return SizedBox(
      width: 200, //sets widht
      height: 200, //sets height
      child: Lottie.asset(
        animationPath,
        width: 200,
        height: 200,
        fit: BoxFit.contain, //keeps the animation within the box without streching it
        // if the container fails to load
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // centers the content vertically
              children: [
                Icon(
                  // icon used in place of the failed to load icon
                  _getWeatherIcon(_mainCondition),
                  size: 100,
                  color: Colors.white,
                ),
                const SizedBox(height: 8), // small vertical spacing
                Text(
                  _mainCondition.toUpperCase(), // shows the current weather of the palce
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // creates the main ui of the page
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // at the top of the application screen
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/animations/logo.jpg',
              height: 40,
              width: 40,
            ),
            const SizedBox(width: 10),
            Text(
              'Weather App',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
      // body of the app
      body: Container(
        // Background gradient for the whole screen
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade400,
              Colors.blue.shade800,
              Colors.purple.shade900,
            ],
          ),
        ),
        // avoids the status bar and notches
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0), //padding around the content
            child: Column(
              children: [
                Image.asset(
                  'assets/animations/logo.jpg', //main logo on the body
                  height: 80,
                ),
                const SizedBox(height: 10),
                // Search Bar container
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30.0),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _cityController, // ready to get the text from the container
                            decoration: InputDecoration(
                              hintText: 'Enter city name',
                              hintStyle: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                              border: InputBorder.none,
                            ),
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            onSubmitted: (value) => _fetchWeatherByCity(value), //search on enter
                          ),
                        ),
                        IconButton(
                          onPressed: () => _fetchWeatherByCity(_cityController.text), //search button
                          icon: const Icon(Icons.search, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30), //space below search bar
                // main content below the search area
                Expanded(
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator()) //loader while fetching
                      : _errorMessage.isNotEmpty //to get the error
                      ? Center(child: Text(_errorMessage))
                      : SingleChildScrollView(
                    child: Column(
                      children: [
                        Text(
                          _cityName, //entered city name
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        //show the weather animation
                        _buildLottieAnimation(_getWeatherAnimation(_mainCondition)),
                        const SizedBox(height: 20),
                        // show the temperature
                        Text(
                          '$_temperature°C',
                          style: GoogleFonts.poppins(
                            fontSize: 72,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                          ),
                        ),
                        // Weather condition (Clear, Rain, etc.)
                        Text(
                          _mainCondition.toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Row of weather details: Wind, Humidity, Feels Like
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildWeatherDetail(
                              icon: Icons.air,
                              label: 'Wind',
                              value: '$_windSpeed km/h',
                            ),
                            _buildWeatherDetail(
                              icon: Icons.water_drop,
                              label: 'Humidity',
                              value: '$_humidity%',
                            ),
                            _buildWeatherDetail(
                              icon: Icons.thermostat,
                              label: 'Feels Like',
                              value: '$_feelsLike°C',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 1. main()
//
// Initializes Flutter and loads .env file with API keys.
//
// Runs the MyApp widget to start the app.
//
// Handles the case if .env file is missing.

// 2. MyApp (Stateless Widget)
//
// The main app container.
//
// Sets app title, theme (dark + Material 3), and the first page (WeatherPage).
//
// 3. WeatherPage (Stateful Widget)
//
// Dynamic widget where weather data changes based on user input or location.
//
// Links to _WeatherPageState which contains the logic and UI updates.
// 4. _WeatherPageState
//
// Holds all the state variables, controllers, and methods for WeatherPage:
//
// State variables:
//
// _cityName, _temperature, _mainCondition, _feelsLike, _humidity, _windSpeed → store weather info.
//
// _isLoading → shows loading spinner while fetching data.
//
// _errorMessage → shows error messages.
//
// _cityController → gets the text input for city name.
// 5. initState()
//
// Runs when the widget is first created.
//
// Calls _fetchWeather() to get weather based on user location immediately.
// 6. _fetchWeather()
//
// Checks location permissions.
//
// Gets user’s current location.
//
// Calls _fetchWeatherByCoordinates() with latitude & longitude.
//
// Handles permission errors or location errors.
// 7. _fetchWeatherByCity(String cityName)
//
// Fetches weather data from OpenWeather API using a city name.
//
// Handles:
//
// Empty input
//
// City not found
//
// HTTP errors or connection failures
//
// Updates the state variables with the fetched data.
// 8. _fetchWeatherByCoordinates(double latitude, double longitude)
//
// Fetches weather data using GPS coordinates.
//
// Handles errors if fetching fails.
//
// Updates the state variables on success.
// 9. _updateWeatherData(Map<String, dynamic> data)
//
// Extracts weather information from API response.
//
// Converts values to String for display.
//
// Updates the UI using setState().
//
// 10. _getWeatherAnimation(String? mainCondition)
//
// Returns the Lottie animation path based on weather condition (e.g., rain → shower rain.json).
//
// Provides a default loader animation if the condition is null.
//
// 11. _getWeatherIcon(String condition)
//
// Returns a Material icon corresponding to the weather (e.g., clouds → Icons.cloud).
//
// 12. _buildWeatherDetail({icon, label, value})
//
// Creates a small weather info card showing:
//
// Icon
//
// Label (e.g., Wind, Humidity)
//
// Value
//
// Styled with semi-transparent background and rounded corners.
//
// 13. _buildLottieAnimation(String animationPath)
//
// Displays a Lottie animation for weather.
//
// If animation fails to load, shows a fallback icon + condition text.
//
// 14. build(BuildContext context)
//
// Main UI layout:
//
// AppBar with logo and title.
//
// Search Bar to enter city name.
//
// Weather info section:
//
// City name
//
// Weather animation
//
// Temperature
//
// Condition
//
// Details row (Wind, Humidity, Feels Like)
//
// Handles loading spinner or error messages.
//
// Uses gradient background and SafeArea padding.




