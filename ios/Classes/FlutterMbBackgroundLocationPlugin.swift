import CoreLocation
import CoreMotion
import Flutter
import UIKit

public class FlutterMbBackgroundLocationPlugin: NSObject, FlutterPlugin, CLLocationManagerDelegate {
    static var locationManager: CLLocationManager?
    static var channel: FlutterMethodChannel?
    var running = false

    // Properties from ContentViewModel
    private let motionActivityManager = CMMotionActivityManager()
    private var motionStateCheckTimer: Timer?
    private var currentActivity: CMMotionActivity?

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

            FlutterMbBackgroundLocationPlugin.locationManager?.desiredAccuracy =
                kCLLocationAccuracyHundredMeters
            FlutterMbBackgroundLocationPlugin.locationManager?.distanceFilter = 100
            FlutterMbBackgroundLocationPlugin.locationManager?.allowsBackgroundLocationUpdates =
                true
            FlutterMbBackgroundLocationPlugin.locationManager?.showsBackgroundLocationIndicator =
                false
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

            FlutterMbBackgroundLocationPlugin.locationManager?.distanceFilter = 100
            FlutterMbBackgroundLocationPlugin.locationManager?.desiredAccuracy =
                kCLLocationAccuracyHundredMeters

            FlutterMbBackgroundLocationPlugin.locationManager?.startUpdatingLocation()
            startMonitoringMotionActivity()
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
            motionStateCheckTimer?.invalidate()
            motionActivityManager.stopActivityUpdates()
            result(true)
        }
    }

    private func startMonitoringMotionActivity() {
        if CMMotionActivityManager.isActivityAvailable() {
            motionActivityManager.startActivityUpdates(to: OperationQueue.main) {
                [weak self] activity in
                guard let self = self else { return }
                self.currentActivity = activity
            }
            startMotionStateCheckTimer()
        } else {
            print("Motion activity is not available.")
        }
    }

    private func startMotionStateCheckTimer() {
        motionStateCheckTimer = Timer.scheduledTimer(
            timeInterval: 7,
            target: self,
            selector: #selector(checkMotionState),
            userInfo: nil,
            repeats: true)
    }

    @objc private func checkMotionState() {
        guard let activity = currentActivity else {
            // No activity data, default to 100 meters
            FlutterMbBackgroundLocationPlugin.locationManager?.desiredAccuracy =
                kCLLocationAccuracyHundredMeters
            FlutterMbBackgroundLocationPlugin.locationManager?.distanceFilter = 100
            print("No activity data, distanceFilter set to 100 meters.")
            return
        }
        if activity.stationary {  // telefon sabit
            FlutterMbBackgroundLocationPlugin.locationManager?.desiredAccuracy =
                kCLLocationAccuracyHundredMeters
            FlutterMbBackgroundLocationPlugin.locationManager?.distanceFilter = 100
            print("User is stationary, distanceFilter set to 100 meters.")
        } else {
            FlutterMbBackgroundLocationPlugin.locationManager?.desiredAccuracy =
                kCLLocationAccuracyNearestTenMeters
            FlutterMbBackgroundLocationPlugin.locationManager?.distanceFilter = 12
            print("User is moving, distanceFilter set to 12 meters.")
        }
    }

    public func locationManager(
        _ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus
    ) {
        switch status {
        case .authorizedAlways:
            // Start location updates if not already running
            print("Authorized for always access.")
        case .authorizedWhenInUse:
            print("Authorized when in use.")
        case .denied, .restricted:
            print("Location access denied or restricted.")
        case .notDetermined:
            manager.requestAlwaysAuthorization()
        @unknown default:
            print("Unknown authorization status.")
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
        guard let location = locations.last else { return }

        let locationData =
            [
                "speed": location.speed,
                "altitude": location.altitude,
                "latitude": location.coordinate.latitude,
                "longitude": location.coordinate.longitude,
                "accuracy": location.horizontalAccuracy,
                "bearing": location.course,
                "time": location.timestamp.timeIntervalSince1970 * 1000,
                "is_mock": false,
            ] as [String: Any]

        FlutterMbBackgroundLocationPlugin.channel?.invokeMethod("location", arguments: locationData)
        print("Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
    }
}
