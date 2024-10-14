import CoreLocation
import Flutter
import UIKit
import CoreMotion

public class SwiftBackgroundLocationPlugin: NSObject, FlutterPlugin, CLLocationManagerDelegate {
    static var locationManager: CLLocationManager?
    static var channel: FlutterMethodChannel?
    var running = false

    // Properties from ContentViewModel
    private let motionActivityManager = CMMotionActivityManager()
    private var motionStateCheckTimer: Timer?
    private var currentActivity: CMMotionActivity?
    
    var stationaryDistanceFilter: Double = 150.0
    var stationaryAccuracy: Int = 3
    var stationaryCheckSecond: Int = 120
    var movingDistanceFilter: Double = 20.0
    var movingAccuracy: Int = 2
    var movingCheckSecond: Int = 7

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

            SwiftBackgroundLocationPlugin.locationManager?.desiredAccuracy = stationaryAccuracy
            SwiftBackgroundLocationPlugin.locationManager?.distanceFilter = stationaryDistanceFilter
            SwiftBackgroundLocationPlugin.locationManager?.allowsBackgroundLocationUpdates = true
            SwiftBackgroundLocationPlugin.locationManager?.showsBackgroundLocationIndicator = false
            SwiftBackgroundLocationPlugin.locationManager?.pausesLocationUpdatesAutomatically = false
        }
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        SwiftBackgroundLocationPlugin.channel?.invokeMethod("location", arguments: "method")

        if call.method == "start_location_service" {
            initLocationManager()
            SwiftBackgroundLocationPlugin.channel?.invokeMethod(
                "location", arguments: "start_location_service")

            SwiftBackgroundLocationPlugin.locationManager?.distanceFilter = stationaryDistanceFilter
            SwiftBackgroundLocationPlugin.locationManager?.desiredAccuracy = stationaryAccuracy

            SwiftBackgroundLocationPlugin.locationManager?.startUpdatingLocation()
            startMonitoringMotionActivity()
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
            motionStateCheckTimer?.invalidate()
            motionActivityManager.stopActivityUpdates()
            result(true)
        }
    }

    private func startMonitoringMotionActivity() {
        if CMMotionActivityManager.isActivityAvailable() {
            motionActivityManager.startActivityUpdates(to: OperationQueue.main) { [weak self] activity in
                guard let self = self else { return }
                self.currentActivity = activity
            }
            startMotionStateCheckTimer()
        } else {
            print("Motion activity is not available.")
        }
    }

    private func startMotionStateCheckTimer() {
        Dispatchqueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            guard let self else { return }
            self.checkMotionState()
        }
    }

    @objc private func checkMotionState() {
        guard let activity = currentActivity else {
            // No activity data, default to 100 meters
            SwiftBackgroundLocationPlugin.locationManager?.desiredAccuracy = decideAccuracy(stationaryAccuracy)
            SwiftBackgroundLocationPlugin.locationManager?.distanceFilter = stationaryDistanceFilter
            print("LOG: No activity data, distanceFilter set to stationaryDistanceFilter meters.")
            return
        }
        if activity.stationary { // telefon sabit
            SwiftBackgroundLocationPlugin.locationManager?.desiredAccuracy = decideAccuracy(stationaryAccuracy)
            SwiftBackgroundLocationPlugin.locationManager?.distanceFilter = stationaryDistanceFilter
            print("LOG: User is stationary, distanceFilter set to stationaryDistanceFilter meters.")
        } else {
            SwiftBackgroundLocationPlugin.locationManager?.desiredAccuracy = decideAccuracy(movingAccuracy)
            SwiftBackgroundLocationPlugin.locationManager?.distanceFilter = movingDistanceFilter
            print("LOG: User is moving, distanceFilter set to movingDistanceFilter meters.")
        }
        
        // Schedule the next check based on current activity
        let interval: TimeInterval
        if let activity = currentActivity, activity.stationary {
            interval = stationaryCheckSecond
        } else {
            interval = movingCheckSecond
        }

        // Invalidate any existing timer before scheduling a new one
        motionStateCheckTimer?.invalidate()
        motionStateCheckTimer = Timer.scheduledTimer(
            timeInterval: interval,
            target: self,
            selector: #selector(checkMotionState),
            userInfo: nil,
            repeats: false)
    }
    
    func decideAccuracy(_ priority: Int) -> CLLocationAccuracy {
        switch priority {
        case 0:
            return kCLLocationAccuracyBest
        case 1:
            return kCLLocationAccuracyBestForNavigation
        case 2:
            return kCLLocationAccuracyNearestTenMeters
        case 3:
            return kCLLocationAccuracyHundredMeters
        case 4:
            return kCLLocationAccuracyKilometer
        case 5:
            return kCLLocationAccuracyThreeKilometers
        case 6:
            if #available(iOS 14.0, *) {
                return kCLLocationAccuracyReduced
            } else {
                return kCLLocationAccuracyHundredMeters
            }
        default:
            return kCLLocationAccuracyHundredMeters
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
        SwiftBackgroundLocationPlugin.channel?.invokeMethod(
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

        SwiftBackgroundLocationPlugin.channel?.invokeMethod("location", arguments: locationData)
        print("LOG: Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
    }
}
