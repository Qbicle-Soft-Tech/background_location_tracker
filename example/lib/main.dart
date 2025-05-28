import 'package:flutter/material.dart';
import 'package:background_locator_2/location_dto.dart';
import 'location_tracker_service.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final LocationTrackerService locationService = LocationTrackerService();
  String logStr = '';
  bool? isRunning;
  LocationDto? lastLocation;

  @override
  void initState() {
    super.initState();
    locationService.initialize(
      onLocationUpdated: (location) {
        setState(() {
          lastLocation = location;
        });
      },
      onLogUpdated: (log) {
        setState(() {
          logStr = log;
        });
      },
    ).then((_) async {
      final running = await locationService.isServiceRunning();
      setState(() {
        isRunning = running;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Flutter background Locator')),
        body: Container(
          padding: const EdgeInsets.all(22),
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildButton('Start', () async {
                  await locationService.start();
                  final running = await locationService.isServiceRunning();
                  setState(() => isRunning = running);
                }),
                _buildButton('Stop', () async {
                  await locationService.stop();
                  final running = await locationService.isServiceRunning();
                  setState(() => isRunning = running);
                }),
                _buildButton('Clear Log', () async {
                  setState(() => logStr = '');
                }),
                Text('Status: ${isRunning == true ? "Is running" : "Is not running"}'),
                Text(logStr),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}
