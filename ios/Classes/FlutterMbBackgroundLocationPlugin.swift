import CoreLocation
import Flutter
import UIKit

public class SwiftBackgroundLocationPlugin: NSObject, FlutterPlugin, CLLocationManagerDelegate {
    static var locationManager: CLLocationManager?
    static var channel: FlutterMethodChannel?
    var running = false

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = SwiftBackgroundLocationPlugin()

        SwiftBackgroundLocationPlugin.channel = FlutterMethodChannel(
            name: "com.mobven.background_location/methods",
            binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: SwiftBackgroundLocationPlugin.channel!)
        SwiftBackgroundLocationPlugin.channel?.setMethodCallHandler(instance.handle)
        instance.running = false
    }

    private func initLocationManager() {
        if SwiftBackgroundLocationPlugin.locationManager == nil {
            SwiftBackgroundLocationPlugin.locationManager = CLLocationManager()
            SwiftBackgroundLocationPlugin.locationManager?.delegate = self
            SwiftBackgroundLocationPlugin.locationManager?.requestAlwaysAuthorization()

            SwiftBackgroundLocationPlugin.locationManager?.allowsBackgroundLocationUpdates = true
            if #available(iOS 11.0, *) {
                SwiftBackgroundLocationPlugin.locationManager?.showsBackgroundLocationIndicator =
                    true
            }
            SwiftBackgroundLocationPlugin.locationManager?.pausesLocationUpdatesAutomatically =
                false
        }
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        SwiftBackgroundLocationPlugin.channel?.invokeMethod("location", arguments: "method")

        if call.method == "start_location_service" {
            initLocationManager()
            SwiftBackgroundLocationPlugin.channel?.invokeMethod(
                "location", arguments: "start_location_service")

            let args = call.arguments as? [String: Any]
            let distanceFilter = args?["distance_filter"] as? Double
            let priority = args?["accuracy"] as? Int

            SwiftBackgroundLocationPlugin.locationManager?.distanceFilter = distanceFilter ?? 0

            switch priority {
            case 0:
                SwiftBackgroundLocationPlugin.locationManager?.desiredAccuracy =
                    kCLLocationAccuracyBest
            case 1:
                SwiftBackgroundLocationPlugin.locationManager?.desiredAccuracy =
                    kCLLocationAccuracyBestForNavigation
            case 2:
                SwiftBackgroundLocationPlugin.locationManager?.desiredAccuracy =
                    kCLLocationAccuracyNearestTenMeters
            case 3:
                SwiftBackgroundLocationPlugin.locationManager?.desiredAccuracy =
                    kCLLocationAccuracyHundredMeters
            case 4:
                SwiftBackgroundLocationPlugin.locationManager?.desiredAccuracy =
                    kCLLocationAccuracyKilometer
            case 5:
                SwiftBackgroundLocationPlugin.locationManager?.desiredAccuracy =
                    kCLLocationAccuracyThreeKilometers
            case 6:
                if #available(iOS 14.0, *) {
                    SwiftBackgroundLocationPlugin.locationManager?.desiredAccuracy =
                        kCLLocationAccuracyReduced
                } else {
                    SwiftBackgroundLocationPlugin.locationManager?.desiredAccuracy =
                        kCLLocationAccuracyHundredMeters
                }
            default:
                SwiftBackgroundLocationPlugin.locationManager?.desiredAccuracy =
                    kCLLocationAccuracyHundredMeters
            }

            SwiftBackgroundLocationPlugin.locationManager?.startUpdatingLocation()
            running = true
            result(true)
        } else if call.method == "is_service_running" {
            result(running)
        } else if call.method == "stop_location_service" {
            initLocationManager()
            running = false
            SwiftBackgroundLocationPlugin.channel?.invokeMethod(
                "location", arguments: "stop_location_service")
            SwiftBackgroundLocationPlugin.locationManager?.stopUpdatingLocation()
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
        SwiftBackgroundLocationPlugin.channel?.invokeMethod(
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

        SwiftBackgroundLocationPlugin.channel?.invokeMethod("location", arguments: location)
    }
}
