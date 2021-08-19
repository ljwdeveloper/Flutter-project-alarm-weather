import 'package:flutter/material.dart';
import 'structures.dart';

class WeatherPage extends StatefulWidget {
  WeatherPage();
  @override
  _WeatherPageState createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  bool isBusy = true;
  var appManager = AppManager();

  Icon weatherIcon = Icon(Icons.query_builder, size: 150, color: Colors.blue);
  @override
  void initState() {
    super.initState();
    appManager.prepareWeatherInfo(() {
      isBusy = false;
      if (appManager.weatherHere!.contains('Clouds')) {
        weatherIcon = Icon(Icons.cloud, size: 150, color: Colors.blue);
      } else if (appManager.weatherHere!.contains('Rain')) {
        weatherIcon = Icon(Icons.grain, size: 150, color: Colors.blue);
      } else if (appManager.weatherHere!.contains('Clear')) {
        weatherIcon = Icon(Icons.wb_sunny, size: 150, color: Colors.blue);
      }
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Text(
            appManager.placeName ?? '',
            style: TextStyle(fontSize: 35, fontWeight: FontWeight.w300),
          ),
          SizedBox(
            height: 20,
          ),
          isBusy ? CircularProgressIndicator() : weatherIcon,
          SizedBox(
            height: 20,
          ),
          Text(
            appManager.weatherHere ?? '',
            style: TextStyle(fontSize: 40, fontWeight: FontWeight.w400),
          )
        ],
      ),
    );
  }
}
