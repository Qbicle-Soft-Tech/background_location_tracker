import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:background_locator_2/background_locator.dart';
import 'package:background_locator_2/location_dto.dart';
import 'package:background_locator_2/settings/android_settings.dart';
import 'package:background_locator_2/settings/ios_settings.dart';
import 'package:background_locator_2/settings/locator_settings.dart';
import 'package:permission_handler/permission_handler.dart';

import 'location_callback_handler.dart';
import 'location_service_repository.dart';
import 'location_db_service.dart';

class LocationTrackerService {
  final ReceivePort port = ReceivePort();
  Function(LocationDto?)? onLocationUpdated;
  Function(String)? onLogUpdated;

  Future<void> initialize({
    required Function(LocationDto?) onLocationUpdated,
    required Function(String) onLogUpdated,
  }) async {
    this.onLocationUpdated = onLocationUpdated;
    this.onLogUpdated = onLogUpdated;

    if (IsolateNameServer.lookupPortByName(LocationServiceRepository.isolateName) != null) {
      IsolateNameServer.removePortNameMapping(LocationServiceRepository.isolateName);
    }

    IsolateNameServer.registerPortWithName(port.sendPort, LocationServiceRepository.isolateName);

    port.listen((dynamic data) async {
      LocationDto? location = data != null ? LocationDto.fromJson(data) : null;
      await BackgroundLocator.updateNotificationText(
        title: "new location received",
        msg: "${DateTime.now()}",
        bigMsg: "${location?.latitude}, ${location?.longitude}",
      );
      onLocationUpdated(location);
      onLogUpdated(location?.toJson().toString() ?? "");
    });

    await BackgroundLocator.initialize();
    await LocationDbService.initDb();
    var res = await LocationDbService.getLocations(employeeId: "1", isSynced: false);
    onLogUpdated(res.toString());
  }

  Future<void> start() async {
    if (await _checkLocationPermission()) {
      await _startLocator();
    }
  }

  Future<void> stop() async {
    await BackgroundLocator.unRegisterLocationUpdate();
  }

  Future<bool> isServiceRunning() async {
    return await BackgroundLocator.isServiceRunning();
  }

  Future<bool> _checkLocationPermission() async {
    final access = await [
      Permission.location,
      Permission.locationAlways,
      Permission.locationWhenInUse,
    ].request();

    var status = access.values.fold(
      PermissionStatus.granted,
          (prev, element) => prev == PermissionStatus.granted && element == PermissionStatus.granted
          ? PermissionStatus.granted
          : PermissionStatus.denied,
    );

    return status == PermissionStatus.granted;
  }

  Future<void> _startLocator() async {
    Map<String, dynamic> data = {'countInit': 1};

    await BackgroundLocator.registerLocationUpdate(
      LocationCallbackHandler.callback,
      initCallback: LocationCallbackHandler.initCallback,
      initDataCallback: data,
      disposeCallback: LocationCallbackHandler.disposeCallback,
      iosSettings: IOSSettings(
        accuracy: LocationAccuracy.NAVIGATION,
        distanceFilter: 0,
        stopWithTerminate: true,
      ),
      autoStop: false,
      androidSettings: AndroidSettings(
        accuracy: LocationAccuracy.NAVIGATION,
        interval: 5,
        distanceFilter: 0,
        client: LocationClient.google,
        androidNotificationSettings: AndroidNotificationSettings(
          notificationChannelName: 'Location tracking',
          notificationTitle: 'Start Location Tracking',
          notificationMsg: 'Track location in background',
          notificationBigMsg:
          'Background location is on to keep the app up-to-date with your location.',
          notificationIconColor: Colors.grey,
          notificationTapCallback: LocationCallbackHandler.notificationCallback,
        ),
      ),
    );
  }
}
