import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mb_background_location/flutter_mb_background_location.dart';

/// BackgroundLocation plugin to get background
/// lcoation updates in iOS and Android
class MBBackgroundLocation {
  // The channel to be used for communication.
  // This channel is also refrenced inside both iOS and Abdroid classes
  static const MethodChannel _channel =
      MethodChannel('com.mobven.background_location/methods');

  /// Stop receiving location updates
  static stopLocationService() async {
    return await _channel.invokeMethod('stop_location_service');
  }

  /// Check if the location update service is running
  static Future<bool> isServiceRunning() async {
    var result = await _channel.invokeMethod('is_service_running');
    return result == true;
  }

  /// Start receiving location updated
  static startLocationService({
    double stationaryDistanceFilter = 150,
    double movingDistanceFilter = 20,
    int stationaryCheckSecond = 120,
    int movingCheckSecond = 7,
    bool forceAndroidLocationManager = false,
    MBLocationAccuracy stationaryAccuracy =
        MBLocationAccuracy.nearestHundredMeters,
    MBLocationAccuracy movingAccuracy = MBLocationAccuracy.nearestTenMeters,
  }) async {
    return await _channel
        .invokeMethod('start_location_service', <String, dynamic>{
      'stationary_distance_filter': stationaryDistanceFilter,
      'force_location_manager': forceAndroidLocationManager,
      "stationary_accuracy": stationaryAccuracy.index,
      "moving_accuracy": movingAccuracy.index,
      "stationary_check_second": stationaryCheckSecond,
      "moving_distance_filter": movingDistanceFilter,
      "moving_check_second": movingCheckSecond,
    });
  }

  /* 
    var stationaryCheckSecond: Int = 120
    var movingDistanceFilter: Double = 20.0
    var movingCheckSecond: Int = 7
   */

  static setAndroidNotification(
      {String? title, String? message, String? icon}) async {
    if (Platform.isAndroid) {
      return await _channel.invokeMethod('set_android_notification',
          <String, dynamic>{'title': title, 'message': message, 'icon': icon});
    } else {
      //return Promise.resolve();
    }
  }

  static setAndroidConfiguration(int interval) async {
    if (Platform.isAndroid) {
      return await _channel.invokeMethod('set_configuration', <String, dynamic>{
        'interval': interval.toString(),
      });
    } else {
      //return Promise.resolve();
    }
  }

  /// Get the current location once.
  Future<Location> getCurrentLocation() async {
    var completer = Completer<Location>();

    var _location = Location();
    await getLocationUpdates((location) {
      _location.latitude = location.latitude;
      _location.longitude = location.longitude;
      _location.accuracy = location.accuracy;
      _location.altitude = location.altitude;
      _location.bearing = location.bearing;
      _location.speed = location.speed;
      _location.time = location.time;
      completer.complete(_location);
    });

    return completer.future;
  }

  /// Register a function to recive location updates as long as the location
  /// service has started
  static getLocationUpdates(Function(Location) location) {
    // add a handler on the channel to recive updates from the native classes
    _channel.setMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'location') {
        var locationData = Map.from(methodCall.arguments);
        // Call the user passed function
        location(
          Location(
              latitude: locationData['latitude'],
              longitude: locationData['longitude'],
              altitude: locationData['altitude'],
              accuracy: locationData['accuracy'],
              bearing: locationData['bearing'],
              speed: locationData['speed'],
              time: locationData['time'],
              isMock: locationData['is_mock']),
        );
      }
    });
  }

  static onLocationError(Function(String) error) {
    _channel.setMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'location_error') {
        var errorData = Map.from(methodCall.arguments);
        error(errorData['message']);
      }
    });
  }
}

/// about the user current location
class Location {
  double? latitude;
  double? longitude;
  double? altitude;
  double? bearing;
  double? accuracy;
  double? speed;
  double? time;
  bool? isMock;

  Location(
      {@required this.longitude,
      @required this.latitude,
      @required this.altitude,
      @required this.accuracy,
      @required this.bearing,
      @required this.speed,
      @required this.time,
      @required this.isMock});

  toMap() {
    var obj = {
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'bearing': bearing,
      'accuracy': accuracy,
      'speed': speed,
      'time': time,
      'is_mock': isMock
    };
    return obj;
  }
}
