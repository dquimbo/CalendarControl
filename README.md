#PBBluetooth iOS framework for all Pebblebee devices.

The Pebblebee iOS framework provides a simple, high-level interface for interacting with Pebblebee Bluetooth hardware, built on top of [Core Bluetooth](https://developer.apple.com/library/ios/documentation/NetworkingInternetWeb/Conceptual/CoreBluetooth_concepts/AboutCoreBluetooth/Introduction.html) and [Core Location](https://developer.apple.com/library/ios/documentation/UserExperience/Conceptual/LocationAwarenessPG/Introduction/Introduction.html).

# Setup
[Download the Pebblebee framework](https://github.com/PebbleBee/Pebblebee-iOS-SDK/archive/master.zip) and add it to your Xcode project, or install with CocoaPods:

```shell
pod 'PBBluetooth'
```

After you run `pod install` (or `pod update`) you can import the framework from your project's source files.

```swift
import PBBluetooth
```

Your project will need to have these background modes enabled in your project's Info.plist file:

```xml
	<key>UIBackgroundModes</key>
	<array>
		<string>bluetooth-central</string>
		<string>bluetooth-peripheral</string>
		<string>location</string>
	</array>
```

You'll also need to include a description of your app's usage of location services under the key `NSLocationAlwaysUsageDescription`.

```xml
	<key>NSLocationAlwaysUsageDescription</key>
	<string>Location services are required for Pebblebee device tracking.</string>
```
Finally, you will need a description for the frameworks ability to broadcast bluetooth data

```xml
	<key>NSBluetoothPeripheralUsageDescription</key>
	<string>To find your Pebblebee Finder we need to be able to transmit bluetooth data.</string>
```
# Device Manager

The heart of the framework revolves around the `PBDeviceManager` class and emitted notifications through `NotificationCenter`.

Make a `PBDeviceManager` at the lowest point in your app that it is needed. I use the `AppDelegate` but any view controller that represents the initial UI where Pebblebee devices are needed will work. 

```Swift
let bluetoothManager = PBDeviceManager(withDevices: nil)
```

You can then enable and or disable Bluetooth scanning and Locaiton updates by setting the appropriate variables on your `PBDeviceManager`

```Swift
bluetoothManager.locationUpdatesEnabled = true
bluetoothManager.scanningEnabled = true
```
# Notifications

The framework emits important event through your app's default [`NotificationCenter`](https://developer.apple.com/reference/foundation/notificationcenter)

The first notifications you will probably be concerned with are the `PBBluetoothStatusNotification` and `PBLocationServiceStatusNotification` Notifications. Register for them like this:

```Swift
        NotificationCenter.default.addObserver(self, selector: #selector(self.bluetoothStatus(_:)), name: PBBluetoothStatusNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.locationStatus(_:)), name: PBLocationServiceStatusNotification, object: nil)
```
These notifications let you know the state of the hardware and app permissions. Use these internally or UI facing to understand the state of the `PBDeviceManager`

Next, you will probably be concerned with the `PBDeviceDidBecomeReachableNotification` and `PBDeviceDidBecomeUnreachableNotification` notifications. 

These let you know when `PBDevice`'s are become 'in range' or 'out of' range. After registering for these notifications you can interact with the `PBDevice` that changed like this:

```Swift
//Function that was registered as the `#selector()` for the `Notification` that you added this class as an observer for.
func newDevice(_ sender: Notification) {
	// Get the device from the `Notification`'s `.object` property.
	guard let device = sender.object as? PBDevice else {
    		return
	}
	
	//Do something with the device
        //Downcast if needed
        switch device {
        case let finder as PBFinder:
            print("Casted as a PBFinder")
        case let honey as PBHoney:
            print("Casted as a PBHoney")
        case is PBStone:
            print("Type checked as a PBStone")
        default:
            return
        }
        
        //Compare to another collection
        if filteredDevices.contains(device) {
            print("In local list")
        }else{
            print("Not in local list")
        }
	
	//Sync local list to `PBDeviceManager`'s `.devices` Set
        self.localArray = Array(self.appDelegate.bluetoothManager.devices)
}
```

# Devices and their features

`PBDevices` have many great and useful properties. Stuff like `.buttonState` and `.batteryValue` or `.locationHistory` and `.inRange` will help you communicate to your user the state of their `PBDevice`. You can also get notificaitons about changes to some of these states through the `NotificaionCenter`. Some examples are `PBBatteryStateNotification` and `PBButtonStateChangeNotification`.

If you want to take advantage of feature sets that are unique to specific `PBDevices` the you should try and cast a device to the call you want.

```Swift
//Try and cast as a finder
guard let finder = device as? PBFinder else {
	return
}
```
One of the core features of a lot of our devices is the ability to 'Find' then. 

Each `PBDevice` sub class has its own find options and corresponding errors. Here is how you 'Find' a `PBFinder`

```Swift
finder.find(option: PBFinderFindOptions.shortRange, withManager: bluetoothManager) { (error) in
    if let e = error {
	print("Error: \(e)")
    }else{
	print("Success!!")
    }
}
```

As you can see you need to specify the 'Find' option and provide an `PBDeiceManager` that will handle the request.

If you want to establish a Bluetooth connection to a `PBDevice` just do this:

```Swift
manager.connectDevice(device: d) { (error) in
	if let e = error {
		print("Error: \(e), Device State: \(d.stateString)")
	}else{
		print("Connected!, Device State: \(d.stateString)")
	}
}
```

Connecting to a device can speed up interacting with some features and is a requirement for other features.

# Logging/Debugging

There is a `Notification` you can subscribe to that will pass you information about what is happening in the framework under the hood. You can subscribe to this notification like this:

```Swift
NotificationCenter.default.addObserver(self, selector: #selector(self.gotDebugNotification(_:)), name: PBDebugNotificaiton, object: nil)
```

You can set the log level like this:

```Swift
PBLogLevel = PBLoggLevelOptions.verbose
```

It is up to you how to use this information. The 'Logg's' that are passed through to the notification are not printed to the console and contain a `PBDebugTitle` and `PBDebugMessage`. Here is how you parse them:

```Swift
func gotDebugNotification(_ sender: Notification) {

	guard let dic = sender.object as? [String: AnyObject] else {
	    return
	}

	guard let title = dic[PBDebugTitleKey] as? String else {
	    return
	}

	guard let message = dic[PBDebugMessageKey] as? String else {
	    return
	}

	//Do what ever you want with the title and message
}
```
# Notes

1) There is a class called `PBBroadcastManager` that handles all of its functionality and purpous internally. However, you should call the `stopLocalBeacon(self)` function in your `applicationDidEnterBackground` function. Here is an example:

```Swift
func applicationDidEnterBackground(_ application: UIApplication) {
	PBBroadcastManager.shared.stopLocalBeacon(self)
}
```

While the phone can not start broadcasting Bluetooth data in the background it can KEEP broadcasting data. This would lead to excessive battery consumption. 



