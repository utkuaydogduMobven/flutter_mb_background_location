import CoreLocation
import Flutter
import UIKit

public class FlutterMbBackgroundLocationPlugin: NSObject, FlutterPlugin, CLLocationManagerDelegate {
    static var locationManager: CLLocationManager?
    static var channel: FlutterMethodChannel?
    var running = false

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = FlutterMbBackgroundLocationPlugin()

        FlutterMbBackgroundLocationPlugin.channel = FlutterMethodChannel(
            name: "com.mobven.background_location/methods",
            binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(
            instance, channel: FlutterMbBackgroundLocationPlugin.channel!)
        FlutterMbBackgroundLocationPlugin.channel?.setMethodCallHandler(instance.handle)
        instance.running = false
    }

    private func initLocationManager() {
        if FlutterMbBackgroundLocationPlugin.locationManager == nil {
            FlutterMbBackgroundLocationPlugin.locationManager = CLLocationManager()
            FlutterMbBackgroundLocationPlugin.locationManager?.delegate = self
            FlutterMbBackgroundLocationPlugin.locationManager?.requestAlwaysAuthorization()

            FlutterMbBackgroundLocationPlugin.locationManager?.allowsBackgroundLocationUpdates =
                true
            if #available(iOS 11.0, *) {
                FlutterMbBackgroundLocationPlugin.locationManager?
                    .showsBackgroundLocationIndicator =
                    true
            }
            FlutterMbBackgroundLocationPlugin.locationManager?.pausesLocationUpdatesAutomatically =
                false
        }
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        FlutterMbBackgroundLocationPlugin.channel?.invokeMethod("location", arguments: "method")

        if call.method == "start_location_service" {
            initLocationManager()
            FlutterMbBackgroundLocationPlugin.channel?.invokeMethod(
                "location", arguments: "start_location_service")

            let args = call.arguments as? [String: Any]
            let distanceFilter = args?["distance_filter"] as? Double
            let priority = args?["accuracy"] as? Int

            FlutterMbBackgroundLocationPlugin.locationManager?.distanceFilter = distanceFilter ?? 0

            switch priority {
            case 0:
                FlutterMbBackgroundLocationPlugin.locationManager?.desiredAccuracy =
                    kCLLocationAccuracyBest
            case 1:
                FlutterMbBackgroundLocationPlugin.locationManager?.desiredAccuracy =
                    kCLLocationAccuracyBestForNavigation
            case 2:
                FlutterMbBackgroundLocationPlugin.locationManager?.desiredAccuracy =
                    kCLLocationAccuracyNearestTenMeters
            case 3:
                FlutterMbBackgroundLocationPlugin.locationManager?.desiredAccuracy =
                    kCLLocationAccuracyHundredMeters
            case 4:
                FlutterMbBackgroundLocationPlugin.locationManager?.desiredAccuracy =
                    kCLLocationAccuracyKilometer
            case 5:
                FlutterMbBackgroundLocationPlugin.locationManager?.desiredAccuracy =
                    kCLLocationAccuracyThreeKilometers
            case 6:
                if #available(iOS 14.0, *) {
                    FlutterMbBackgroundLocationPlugin.locationManager?.desiredAccuracy =
                        kCLLocationAccuracyReduced
                } else {
                    FlutterMbBackgroundLocationPlugin.locationManager?.desiredAccuracy =
                        kCLLocationAccuracyHundredMeters
                }
            default:
                FlutterMbBackgroundLocationPlugin.locationManager?.desiredAccuracy =
                    kCLLocationAccuracyHundredMeters
            }

            FlutterMbBackgroundLocationPlugin.locationManager?.startUpdatingLocation()
            running = true
            result(true)
        } else if call.method == "is_service_running" {
            result(running)
        } else if call.method == "stop_location_service" {
            initLocationManager()
            running = false
            FlutterMbBackgroundLocationPlugin.channel?.invokeMethod(
                "location", arguments: "stop_location_service")
            FlutterMbBackgroundLocationPlugin.locationManager?.stopUpdatingLocation()
            result(true)
        }
    }

    public func locationManager(
        _ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus
    ) {
        switch status {
        case .authorizedAlways:
            print("")
        // Start location updates if not already running
        case .authorizedWhenInUse:
            print("")
        // Optionally, start location updates with limitations
        case .denied, .restricted:
            print("")
        // Handle denied access appropriately
        case .notDetermined:
            // Request permission if needed
            manager.requestAlwaysAuthorization()
        @unknown default:
            print("")
            // Handle future cases
            break
        }
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Handle error appropriately
        FlutterMbBackgroundLocationPlugin.channel?.invokeMethod(
            "location_error", arguments: error.localizedDescription)
    }

    public func locationManager(
        _ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]
    ) {
        let location =
            [
                "speed": locations.last!.speed,
                "altitude": locations.last!.altitude,
                "latitude": locations.last!.coordinate.latitude,
                "longitude": locations.last!.coordinate.longitude,
                "accuracy": locations.last!.horizontalAccuracy,
                "bearing": locations.last!.course,
                "time": locations.last!.timestamp.timeIntervalSince1970 * 1000,
                "is_mock": false,
            ] as [String: Any]

        FlutterMbBackgroundLocationPlugin.channel?.invokeMethod("location", arguments: location)
    }
}
