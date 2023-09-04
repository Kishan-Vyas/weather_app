import 'dart:convert';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:weather_app/hourly_forcast_item.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'additional_info_item.dart';
import 'package:weather_app/_secrets.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final TextEditingController textEditingController = TextEditingController();
  late Future<Map<String, dynamic>> weather;
  String cirtyName = 'Rajkot';
  Future<Map<String, dynamic>> getCurrentWeather() async {
    try {
      final res = await http.get(
        Uri.parse(
            'https://api.openweathermap.org/data/2.5/forecast?q=$cirtyName,india&APPID=$openWeatherAPIKey'),
      );

      final data = jsonDecode(res.body);

      if (data['cod'] != '200') {
        throw 'unexpected error...';
      }

      return data;
    } catch (e) {
      throw e;
    }
  }

  @override
  void initState() {
    super.initState();
    weather = getCurrentWeather();
  }

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderSide: const BorderSide(
        width: 2.0,
        style: BorderStyle.solid,
      ),
      borderRadius: BorderRadius.circular(
        10.0,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Weather of $cirtyName',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: () {
                setState(() {
                  weather = getCurrentWeather();
                });
              },
              icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder(
        future: weather,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          final data = snapshot.data!;
          final currentWeatherData = data['list'][0];

          final currentTemp =
              (currentWeatherData['main']['temp'] - 273.15).toStringAsFixed(2);
          final currentSky = currentWeatherData['weather'][0]['main'];
          final currentPressure = currentWeatherData['main']['pressure'];
          final currentWindSpeed = currentWeatherData['wind']['speed'];
          final currentHumidity = currentWeatherData['main']['humidity'];

          IconData iconData = Icons.cloud;
          if (currentSky == 'Clouds') {
            iconData = Icons.cloud;
          } else if (currentSky == 'Rain') {
            iconData = Icons.cloudy_snowing;
          } else {
            iconData = Icons.sunny;
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main Card
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      elevation: 13,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: 10,
                            sigmaY: 10,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Text(
                                  '$currentTemp °C',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(
                                  height: 16,
                                ),
                                Icon(
                                  iconData,
                                  size: 64,
                                ),
                                const SizedBox(
                                  height: 16,
                                ),
                                Text(
                                  currentSky,
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Hourly Forecast',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Weather Card
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      itemCount: 5,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        final hourlyForcast = data['list'][index + 1];
                        final time = DateTime.parse(hourlyForcast['dt_txt']);
                        return HourlyForeCastItem(
                          time: DateFormat.j().format(time),
                          icon: hourlyForcast['weather'][0]['main'] == 'Clouds'
                              ? Icons.cloud
                              : hourlyForcast['weather'][0]['main'] == 'Rain'
                                  ? Icons.cloudy_snowing
                                  : Icons.sunny,
                          temp: (hourlyForcast['main']['temp'] - 273.15)
                              .toStringAsFixed(2),
                        );
                      },
                    ),
                  ),

                  // ListView.builder(itemBuilder: itemBuilder)
                  const SizedBox(height: 20),
                  // Additional information
                  const Text(
                    'Additional Information',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      AdditionalInfoItem(
                        icon: Icons.water_drop,
                        label: 'Humidity',
                        value: currentHumidity.toString(),
                      ),
                      AdditionalInfoItem(
                        icon: Icons.air,
                        label: 'Wind Speed',
                        value: currentWindSpeed.toString(),
                      ),
                      AdditionalInfoItem(
                        icon: Icons.beach_access,
                        label: 'Pressure',
                        value: currentPressure.toString(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(10),
                    child: TextField(
                      controller: textEditingController,
                      onEditingComplete: update,
                      style: const TextStyle(
                        color: Colors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Change City!!',
                        hintStyle: const TextStyle(
                          color: Colors.black,
                        ),
                        prefixIcon: const Icon(Icons.location_city),
                        prefixIconColor: Colors.black,
                        filled: true,
                        fillColor: Colors.white,
                        focusedBorder: border,
                        enabledBorder: border,
                      ),
                    )
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void update() {
    try{
      setState(() {
        cirtyName = textEditingController.text;
      weather = getCurrentWeather();
    });
    }
    catch(e) {
      print(e);
    }
    
  }
}
