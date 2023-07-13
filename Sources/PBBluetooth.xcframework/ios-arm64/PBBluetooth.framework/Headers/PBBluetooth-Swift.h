#if 0
#elif defined(__arm64__) && __arm64__
// Generated by Apple Swift version 5.8.1 (swiftlang-5.8.0.124.5 clang-1403.0.22.11.100)
#ifndef PBBLUETOOTH_SWIFT_H
#define PBBLUETOOTH_SWIFT_H
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgcc-compat"

#if !defined(__has_include)
# define __has_include(x) 0
#endif
#if !defined(__has_attribute)
# define __has_attribute(x) 0
#endif
#if !defined(__has_feature)
# define __has_feature(x) 0
#endif
#if !defined(__has_warning)
# define __has_warning(x) 0
#endif

#if __has_include(<swift/objc-prologue.h>)
# include <swift/objc-prologue.h>
#endif

#pragma clang diagnostic ignored "-Wauto-import"
#if defined(__OBJC__)
#include <Foundation/Foundation.h>
#endif
#if defined(__cplusplus)
#include <cstdint>
#include <cstddef>
#include <cstdbool>
#include <cstring>
#include <stdlib.h>
#include <new>
#include <type_traits>
#else
#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>
#include <string.h>
#endif
#if defined(__cplusplus)
#if __has_include(<ptrauth.h>)
# include <ptrauth.h>
#else
# ifndef __ptrauth_swift_value_witness_function_pointer
#  define __ptrauth_swift_value_witness_function_pointer(x)
# endif
#endif
#endif

#if !defined(SWIFT_TYPEDEFS)
# define SWIFT_TYPEDEFS 1
# if __has_include(<uchar.h>)
#  include <uchar.h>
# elif !defined(__cplusplus)
typedef uint_least16_t char16_t;
typedef uint_least32_t char32_t;
# endif
typedef float swift_float2  __attribute__((__ext_vector_type__(2)));
typedef float swift_float3  __attribute__((__ext_vector_type__(3)));
typedef float swift_float4  __attribute__((__ext_vector_type__(4)));
typedef double swift_double2  __attribute__((__ext_vector_type__(2)));
typedef double swift_double3  __attribute__((__ext_vector_type__(3)));
typedef double swift_double4  __attribute__((__ext_vector_type__(4)));
typedef int swift_int2  __attribute__((__ext_vector_type__(2)));
typedef int swift_int3  __attribute__((__ext_vector_type__(3)));
typedef int swift_int4  __attribute__((__ext_vector_type__(4)));
typedef unsigned int swift_uint2  __attribute__((__ext_vector_type__(2)));
typedef unsigned int swift_uint3  __attribute__((__ext_vector_type__(3)));
typedef unsigned int swift_uint4  __attribute__((__ext_vector_type__(4)));
#endif

#if !defined(SWIFT_PASTE)
# define SWIFT_PASTE_HELPER(x, y) x##y
# define SWIFT_PASTE(x, y) SWIFT_PASTE_HELPER(x, y)
#endif
#if !defined(SWIFT_METATYPE)
# define SWIFT_METATYPE(X) Class
#endif
#if !defined(SWIFT_CLASS_PROPERTY)
# if __has_feature(objc_class_property)
#  define SWIFT_CLASS_PROPERTY(...) __VA_ARGS__
# else
#  define SWIFT_CLASS_PROPERTY(...) 
# endif
#endif
#if !defined(SWIFT_RUNTIME_NAME)
# if __has_attribute(objc_runtime_name)
#  define SWIFT_RUNTIME_NAME(X) __attribute__((objc_runtime_name(X)))
# else
#  define SWIFT_RUNTIME_NAME(X) 
# endif
#endif
#if !defined(SWIFT_COMPILE_NAME)
# if __has_attribute(swift_name)
#  define SWIFT_COMPILE_NAME(X) __attribute__((swift_name(X)))
# else
#  define SWIFT_COMPILE_NAME(X) 
# endif
#endif
#if !defined(SWIFT_METHOD_FAMILY)
# if __has_attribute(objc_method_family)
#  define SWIFT_METHOD_FAMILY(X) __attribute__((objc_method_family(X)))
# else
#  define SWIFT_METHOD_FAMILY(X) 
# endif
#endif
#if !defined(SWIFT_NOESCAPE)
# if __has_attribute(noescape)
#  define SWIFT_NOESCAPE __attribute__((noescape))
# else
#  define SWIFT_NOESCAPE 
# endif
#endif
#if !defined(SWIFT_RELEASES_ARGUMENT)
# if __has_attribute(ns_consumed)
#  define SWIFT_RELEASES_ARGUMENT __attribute__((ns_consumed))
# else
#  define SWIFT_RELEASES_ARGUMENT 
# endif
#endif
#if !defined(SWIFT_WARN_UNUSED_RESULT)
# if __has_attribute(warn_unused_result)
#  define SWIFT_WARN_UNUSED_RESULT __attribute__((warn_unused_result))
# else
#  define SWIFT_WARN_UNUSED_RESULT 
# endif
#endif
#if !defined(SWIFT_NORETURN)
# if __has_attribute(noreturn)
#  define SWIFT_NORETURN __attribute__((noreturn))
# else
#  define SWIFT_NORETURN 
# endif
#endif
#if !defined(SWIFT_CLASS_EXTRA)
# define SWIFT_CLASS_EXTRA 
#endif
#if !defined(SWIFT_PROTOCOL_EXTRA)
# define SWIFT_PROTOCOL_EXTRA 
#endif
#if !defined(SWIFT_ENUM_EXTRA)
# define SWIFT_ENUM_EXTRA 
#endif
#if !defined(SWIFT_CLASS)
# if __has_attribute(objc_subclassing_restricted)
#  define SWIFT_CLASS(SWIFT_NAME) SWIFT_RUNTIME_NAME(SWIFT_NAME) __attribute__((objc_subclassing_restricted)) SWIFT_CLASS_EXTRA
#  define SWIFT_CLASS_NAMED(SWIFT_NAME) __attribute__((objc_subclassing_restricted)) SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_CLASS_EXTRA
# else
#  define SWIFT_CLASS(SWIFT_NAME) SWIFT_RUNTIME_NAME(SWIFT_NAME) SWIFT_CLASS_EXTRA
#  define SWIFT_CLASS_NAMED(SWIFT_NAME) SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_CLASS_EXTRA
# endif
#endif
#if !defined(SWIFT_RESILIENT_CLASS)
# if __has_attribute(objc_class_stub)
#  define SWIFT_RESILIENT_CLASS(SWIFT_NAME) SWIFT_CLASS(SWIFT_NAME) __attribute__((objc_class_stub))
#  define SWIFT_RESILIENT_CLASS_NAMED(SWIFT_NAME) __attribute__((objc_class_stub)) SWIFT_CLASS_NAMED(SWIFT_NAME)
# else
#  define SWIFT_RESILIENT_CLASS(SWIFT_NAME) SWIFT_CLASS(SWIFT_NAME)
#  define SWIFT_RESILIENT_CLASS_NAMED(SWIFT_NAME) SWIFT_CLASS_NAMED(SWIFT_NAME)
# endif
#endif
#if !defined(SWIFT_PROTOCOL)
# define SWIFT_PROTOCOL(SWIFT_NAME) SWIFT_RUNTIME_NAME(SWIFT_NAME) SWIFT_PROTOCOL_EXTRA
# define SWIFT_PROTOCOL_NAMED(SWIFT_NAME) SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_PROTOCOL_EXTRA
#endif
#if !defined(SWIFT_EXTENSION)
# define SWIFT_EXTENSION(M) SWIFT_PASTE(M##_Swift_, __LINE__)
#endif
#if !defined(OBJC_DESIGNATED_INITIALIZER)
# if __has_attribute(objc_designated_initializer)
#  define OBJC_DESIGNATED_INITIALIZER __attribute__((objc_designated_initializer))
# else
#  define OBJC_DESIGNATED_INITIALIZER 
# endif
#endif
#if !defined(SWIFT_ENUM_ATTR)
# if __has_attribute(enum_extensibility)
#  define SWIFT_ENUM_ATTR(_extensibility) __attribute__((enum_extensibility(_extensibility)))
# else
#  define SWIFT_ENUM_ATTR(_extensibility) 
# endif
#endif
#if !defined(SWIFT_ENUM)
# define SWIFT_ENUM(_type, _name, _extensibility) enum _name : _type _name; enum SWIFT_ENUM_ATTR(_extensibility) SWIFT_ENUM_EXTRA _name : _type
# if __has_feature(generalized_swift_name)
#  define SWIFT_ENUM_NAMED(_type, _name, SWIFT_NAME, _extensibility) enum _name : _type _name SWIFT_COMPILE_NAME(SWIFT_NAME); enum SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_ENUM_ATTR(_extensibility) SWIFT_ENUM_EXTRA _name : _type
# else
#  define SWIFT_ENUM_NAMED(_type, _name, SWIFT_NAME, _extensibility) SWIFT_ENUM(_type, _name, _extensibility)
# endif
#endif
#if !defined(SWIFT_UNAVAILABLE)
# define SWIFT_UNAVAILABLE __attribute__((unavailable))
#endif
#if !defined(SWIFT_UNAVAILABLE_MSG)
# define SWIFT_UNAVAILABLE_MSG(msg) __attribute__((unavailable(msg)))
#endif
#if !defined(SWIFT_AVAILABILITY)
# define SWIFT_AVAILABILITY(plat, ...) __attribute__((availability(plat, __VA_ARGS__)))
#endif
#if !defined(SWIFT_WEAK_IMPORT)
# define SWIFT_WEAK_IMPORT __attribute__((weak_import))
#endif
#if !defined(SWIFT_DEPRECATED)
# define SWIFT_DEPRECATED __attribute__((deprecated))
#endif
#if !defined(SWIFT_DEPRECATED_MSG)
# define SWIFT_DEPRECATED_MSG(...) __attribute__((deprecated(__VA_ARGS__)))
#endif
#if !defined(SWIFT_DEPRECATED_OBJC)
# if __has_feature(attribute_diagnose_if_objc)
#  define SWIFT_DEPRECATED_OBJC(Msg) __attribute__((diagnose_if(1, Msg, "warning")))
# else
#  define SWIFT_DEPRECATED_OBJC(Msg) SWIFT_DEPRECATED_MSG(Msg)
# endif
#endif
#if defined(__OBJC__)
#if !defined(IBSegueAction)
# define IBSegueAction 
#endif
#endif
#if !defined(SWIFT_EXTERN)
# if defined(__cplusplus)
#  define SWIFT_EXTERN extern "C"
# else
#  define SWIFT_EXTERN extern
# endif
#endif
#if !defined(SWIFT_CALL)
# define SWIFT_CALL __attribute__((swiftcall))
#endif
#if !defined(SWIFT_INDIRECT_RESULT)
# define SWIFT_INDIRECT_RESULT __attribute__((swift_indirect_result))
#endif
#if !defined(SWIFT_CONTEXT)
# define SWIFT_CONTEXT __attribute__((swift_context))
#endif
#if !defined(SWIFT_ERROR_RESULT)
# define SWIFT_ERROR_RESULT __attribute__((swift_error_result))
#endif
#if defined(__cplusplus)
# define SWIFT_NOEXCEPT noexcept
#else
# define SWIFT_NOEXCEPT 
#endif
#if defined(_WIN32)
#if !defined(SWIFT_IMPORT_STDLIB_SYMBOL)
# define SWIFT_IMPORT_STDLIB_SYMBOL __declspec(dllimport)
#endif
#else
#if !defined(SWIFT_IMPORT_STDLIB_SYMBOL)
# define SWIFT_IMPORT_STDLIB_SYMBOL 
#endif
#endif
#if defined(__OBJC__)
#if __has_feature(objc_modules)
#if __has_warning("-Watimport-in-framework-header")
#pragma clang diagnostic ignored "-Watimport-in-framework-header"
#endif
@import CoreBluetooth;
@import CoreLocation;
@import Dispatch;
@import Foundation;
@import ObjectiveC;
#endif

#endif
#pragma clang diagnostic ignored "-Wproperty-attribute-mismatch"
#pragma clang diagnostic ignored "-Wduplicate-method-arg"
#if __has_warning("-Wpragma-clang-attribute")
# pragma clang diagnostic ignored "-Wpragma-clang-attribute"
#endif
#pragma clang diagnostic ignored "-Wunknown-pragmas"
#pragma clang diagnostic ignored "-Wnullability"
#pragma clang diagnostic ignored "-Wdollar-in-identifier-extension"

#if __has_attribute(external_source_symbol)
# pragma push_macro("any")
# undef any
# pragma clang attribute push(__attribute__((external_source_symbol(language="Swift", defined_in="PBBluetooth",generated_declaration))), apply_to=any(function,enum,objc_interface,objc_category,objc_protocol))
# pragma pop_macro("any")
#endif

#if defined(__OBJC__)



/// The <code>PBBroadcastManager</code> is mostly used internally. However, you should call the shared instances’ <code>.stopLocalBeacon(_ sender: AnyObject)</code> function in your <code>appDidEnterBackground</code> app delegate class.
SWIFT_CLASS("_TtC11PBBluetooth18PBBroadcastManager")
@interface PBBroadcastManager : NSObject
- (void)requestAuthorizationWithQueue:(dispatch_queue_t _Nullable)withQueue;
/// This function shuts down all phone iBeacon broadcasting. We recommnd that you call this in your ‘applicationDidEnterBackground’ function. Continiously running the braodcast manager in the background will reduce battery life and will cause some devices to behave unexpectidly when the app is brought to the active state.
/// -Paramaters:
/// -sender: The object that is requesting the iBeacon signal to be shut down.
- (void)stopLocalBeacon:(id _Nonnull)sender;
- (nonnull instancetype)init OBJC_DESIGNATED_INITIALIZER;
@end

@class CBPeripheralManager;

@interface PBBroadcastManager (SWIFT_EXTENSION(PBBluetooth)) <CBPeripheralManagerDelegate>
- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager * _Nonnull)peripheral error:(NSError * _Nullable)error;
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager * _Nonnull)peripheral;
@end

@class NSString;
@class NSDate;
@class CLLocation;
@class NSData;

/// Abstract base class for objects representing Pebblebee Bluetooth devices. The device can store user-assigned data and report attribute updates to its delegate.
SWIFT_CLASS("_TtC11PBBluetooth8PBDevice")
@interface PBDevice : NSObject
/// A brief text description given to the device, like “Car keys” or “Jon’s Finder”.
@property (nonatomic, copy) NSString * _Nullable name;
/// A unique identifier (currently the MAC address for every Pebblebee device) in <code>String</code> format.
@property (nonatomic, copy) NSString * _Null_unspecified macAddress;
/// The system generated date that the ‘PBDevice’ was last scanned by the systems bluetooth hardware
@property (nonatomic, readonly, copy) NSDate * _Nullable lastSeen;
/// The last locaiton of this device
@property (nonatomic, readonly, strong) CLLocation * _Nullable lastLocation;
/// Lets us know if the device is currently in range, or was in range when the app was last launched.
@property (nonatomic, readonly) BOOL inRange;
/// The raw advertised manufactureurs data packet. Should be used for debug and technical purposes only.
@property (nonatomic, readonly, copy) NSData * _Nullable rawMFData;
/// Property that complements the device’s testing delegate. This represents the current number of packets the manager has received for this device.
@property (nonatomic) NSInteger packetCount;
@property (nonatomic, readonly, copy) NSString * _Nullable stateString;
/// Overriden hash value for <code>PBDevice</code>’s
@property (nonatomic, readonly) NSUInteger hash;
/// This function will clear all history for the following varibles: <code>rawRSSIHistory</code>, <code>weightedRSSIHistory</code>, <code>locationHistory</code>, <code>batteryHistory</code>, and <code>temperatureHistory</code>.
- (void)clearHistory;
- (void)setTempCalibrationWith_currentTempReading:(NSInteger)_currentTempReading;
- (void)setTempCalibrationOffsetWith_currentOffset:(NSInteger)_currentOffset;
- (NSInteger)getTempCalibrationOffset SWIFT_WARN_UNUSED_RESULT;
- (BOOL)calibratedTemp SWIFT_WARN_UNUSED_RESULT;
/// Starts the discovery sequence for characteristics and services. This will not do anything if the device is not connected. Call this when a connection request for a device has returned with out an error.
- (void)discoverServices;
- (nonnull instancetype)init SWIFT_UNAVAILABLE;
+ (nonnull instancetype)new SWIFT_UNAVAILABLE_MSG("-init is unavailable");
@end

@class PBDeviceManager;

/// Class that represents Pebblebee’s Finder product.
SWIFT_CLASS("_TtC11PBBluetooth8PBFinder")
@interface PBFinder : PBDevice
/// Starts the discovery sequence for characteristics and services. This will not do anything if the device is not connected. Call this when a connection request for a device has returned with out an error.
- (void)discoverServices;
/// <code>PBFinder</code>’s change to a slow broadcast mode after 5 minutes. Calling this function will attempt to <code>wakeup</code> the finder. The State of the advertisement is broadcast by the <code>PBFinderAdvertisementStateNotification</code> and represented by the <code>advertisementState</code> property.
/// \param m A <code>PBDeviceManager</code> that will be used to wake up the <code>PBFinder</code>
///
- (void)wakeUpFinderWithManager:(PBDeviceManager * _Nonnull)m;
@end


/// Class that represents Pebblebee’s PB Card product.
SWIFT_CLASS("_TtC11PBBluetooth6PBCard")
@interface PBCard : PBFinder
@end



@interface PBDevice (SWIFT_EXTENSION(PBBluetooth))
/// This function returns a human readable <code>String</code> that represents state of the <code>PBDevices</code> button.
///
/// returns:
/// String that represents the human readable state of the <code>PBDevices</code>’s button
- (NSString * _Nonnull)getButtonStateString SWIFT_WARN_UNUSED_RESULT;
@end

@class CBPeripheral;
@class CBService;
@class CBCharacteristic;
@class CBDescriptor;
@class NSNumber;

@interface PBDevice (SWIFT_EXTENSION(PBBluetooth)) <CBPeripheralDelegate>
- (void)peripheral:(CBPeripheral * _Nonnull)peripheral didDiscoverServices:(NSError * _Nullable)error;
- (void)peripheral:(CBPeripheral * _Nonnull)peripheral didDiscoverIncludedServicesForService:(CBService * _Nonnull)service error:(NSError * _Nullable)error;
- (void)peripheral:(CBPeripheral * _Nonnull)peripheral didDiscoverCharacteristicsForService:(CBService * _Nonnull)service error:(NSError * _Nullable)error;
- (void)peripheral:(CBPeripheral * _Nonnull)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic * _Nonnull)characteristic error:(NSError * _Nullable)error;
- (void)peripheral:(CBPeripheral * _Nonnull)peripheral didUpdateValueForCharacteristic:(CBCharacteristic * _Nonnull)characteristic error:(NSError * _Nullable)error;
- (void)peripheral:(CBPeripheral * _Nonnull)peripheral didUpdateValueForDescriptor:(CBDescriptor * _Nonnull)descriptor error:(NSError * _Nullable)error;
- (void)peripheral:(CBPeripheral * _Nonnull)peripheral didWriteValueForCharacteristic:(CBCharacteristic * _Nonnull)characteristic error:(NSError * _Nullable)error;
- (void)peripheral:(CBPeripheral * _Nonnull)peripheral didWriteValueForDescriptor:(CBDescriptor * _Nonnull)descriptor error:(NSError * _Nullable)error;
- (void)peripheral:(CBPeripheral * _Nonnull)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic * _Nonnull)characteristic error:(NSError * _Nullable)error;
- (void)peripheral:(CBPeripheral * _Nonnull)peripheral didReadRSSI:(NSNumber * _Nonnull)RSSI error:(NSError * _Nullable)error;
- (void)peripheralDidUpdateName:(CBPeripheral * _Nonnull)peripheral;
- (void)peripheral:(CBPeripheral * _Nonnull)peripheral didModifyServices:(NSArray<CBService *> * _Nonnull)invalidatedServices;
@end


/// <code>PBDeviceManager</code> provides a simple, high-level interface for interacting with Pebblebee devices.
SWIFT_CLASS("_TtC11PBBluetooth15PBDeviceManager")
@interface PBDeviceManager : NSObject
- (nonnull instancetype)init SWIFT_UNAVAILABLE;
+ (nonnull instancetype)new SWIFT_UNAVAILABLE_MSG("-init is unavailable");
/// Enable or disable scanning. Can be called at any time. If iOS’s bluetooth hardware is not ready to scann the app will wait for it to be.
@property (nonatomic) BOOL scanningEnabled;
/// Enable or disable location updates, including when the app in running in the background. Your app must register for location updates via its required background modes before enabling location updates.
@property (nonatomic) BOOL locationUpdatesEnabled;
@property (nonatomic) BOOL headingUpdatesEnabled;
/// The set of <code>PBDevice</code>s that the bluetooth has scanned. This gets auto populated with new <code>PBDevice</code>s as the manager sees them. If you have <code>PBDevice</code>s that you want bluetooth to know about but it has not scanned yet, you can instantiate the <code>PBDeviceManager</code> with an array of <code>PBDevice</code>s or you can add <code>PBDevice</code>s with the <code>addDevice</code> function on your <code>PBDeviceManager</code>.
@property (nonatomic, copy) NSSet<PBDevice *> * _Nonnull devices;
/// Function that quickly starts and stops scanning in the Core Bluetooth manager
/// \param sender An objects that calls this function
///
- (void)resetScan:(id _Nonnull)sender;
- (void)configureRegionMonitoringWithDeviceMACtoMonitor:(NSArray<NSString *> * _Nonnull)deviceMACtoMonitor;
- (void)configureRegionMonitoringCallWithDeviceMACtoMonitor:(NSArray<NSString *> * _Nonnull)deviceMACtoMonitor;
@end

@class CBCentralManager;

@interface PBDeviceManager (SWIFT_EXTENSION(PBBluetooth)) <CBCentralManagerDelegate>
- (void)centralManager:(CBCentralManager * _Nonnull)central didConnectPeripheral:(CBPeripheral * _Nonnull)peripheral;
- (void)centralManager:(CBCentralManager * _Nonnull)central didFailToConnectPeripheral:(CBPeripheral * _Nonnull)peripheral error:(NSError * _Nullable)error;
- (void)centralManager:(CBCentralManager * _Nonnull)central didDisconnectPeripheral:(CBPeripheral * _Nonnull)peripheral error:(NSError * _Nullable)error;
- (void)centralManager:(CBCentralManager * _Nonnull)central didDiscoverPeripheral:(CBPeripheral * _Nonnull)peripheral advertisementData:(NSDictionary<NSString *, id> * _Nonnull)advertisementData RSSI:(NSNumber * _Nonnull)RSSI;
- (void)centralManagerDidUpdateState:(CBCentralManager * _Nonnull)central;
@end


@class CLLocationManager;
@class CLRegion;
@class CLHeading;

@interface PBDeviceManager (SWIFT_EXTENSION(PBBluetooth)) <CLLocationManagerDelegate>
- (void)locationManager:(CLLocationManager * _Nonnull)manager didUpdateLocations:(NSArray<CLLocation *> * _Nonnull)locations;
- (void)locationManager:(CLLocationManager * _Nonnull)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion * _Nonnull)region;
- (void)locationManager:(CLLocationManager * _Nonnull)manager monitoringDidFailForRegion:(CLRegion * _Nullable)region withError:(NSError * _Nonnull)error;
- (void)locationManager:(CLLocationManager * _Nonnull)manager didStartMonitoringForRegion:(CLRegion * _Nonnull)region;
- (void)locationManager:(CLLocationManager * _Nonnull)manager didFailWithError:(NSError * _Nonnull)error;
- (void)locationManager:(CLLocationManager * _Nonnull)manager didUpdateHeading:(CLHeading * _Nonnull)newHeading;
- (void)locationManager:(CLLocationManager * _Nonnull)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status;
@end





@interface PBFinder (SWIFT_EXTENSION(PBBluetooth))
- (void)peripheral:(CBPeripheral * _Nonnull)peripheral didDiscoverServices:(NSError * _Nullable)error;
- (void)peripheral:(CBPeripheral * _Nonnull)peripheral didDiscoverCharacteristicsForService:(CBService * _Nonnull)service error:(NSError * _Nullable)error;
- (void)peripheral:(CBPeripheral * _Nonnull)peripheral didWriteValueForCharacteristic:(CBCharacteristic * _Nonnull)characteristic error:(NSError * _Nullable)error;
@end



/// Class that represents Pebblebee’s PB Card product.
SWIFT_CLASS("_TtC11PBBluetooth9PBFinder2")
@interface PBFinder2 : PBFinder
@end


/// Class that represents Pebblebee’s Found with the latest Firmware.
SWIFT_CLASS("_TtC11PBBluetooth7PBFound")
@interface PBFound : PBDevice
- (void)discoverServices;
@end






@interface PBFound (SWIFT_EXTENSION(PBBluetooth))
- (void)peripheral:(CBPeripheral * _Nonnull)peripheral didDiscoverServices:(NSError * _Nullable)error;
- (void)peripheral:(CBPeripheral * _Nonnull)peripheral didDiscoverCharacteristicsForService:(CBService * _Nonnull)service error:(NSError * _Nullable)error;
- (void)peripheral:(CBPeripheral * _Nonnull)peripheral didWriteValueForCharacteristic:(CBCharacteristic * _Nonnull)characteristic error:(NSError * _Nullable)error;
- (void)peripheral:(CBPeripheral * _Nonnull)peripheral didUpdateValueForCharacteristic:(CBCharacteristic * _Nonnull)characteristic error:(NSError * _Nullable)error;
@end






/// The PBFound version compatible with advertised Model Number 14
SWIFT_CLASS("_TtC11PBBluetooth11PBFoundRC20")
@interface PBFoundRC20 : PBFinder
- (void)discoverServices;
@end


@interface PBFoundRC20 (SWIFT_EXTENSION(PBBluetooth))
- (void)peripheral:(CBPeripheral * _Nonnull)peripheral didDiscoverServices:(NSError * _Nullable)error;
- (void)peripheral:(CBPeripheral * _Nonnull)peripheral didDiscoverCharacteristicsForService:(CBService * _Nonnull)service error:(NSError * _Nullable)error;
- (void)peripheral:(CBPeripheral * _Nonnull)peripheral didWriteValueForCharacteristic:(CBCharacteristic * _Nonnull)characteristic error:(NSError * _Nullable)error;
- (void)peripheral:(CBPeripheral * _Nonnull)peripheral didUpdateValueForCharacteristic:(CBCharacteristic * _Nonnull)characteristic error:(NSError * _Nullable)error;
@end





/// This class represents our Honey Product and all the interactions available.
SWIFT_CLASS("_TtC11PBBluetooth7PBHoney")
@interface PBHoney : PBDevice
/// Call this function after a successful connection to discover the services.
- (void)discoverServices;
@end



@interface PBHoney (SWIFT_EXTENSION(PBBluetooth))
- (void)peripheral:(CBPeripheral * _Nonnull)peripheral didDiscoverServices:(NSError * _Nullable)error;
- (void)peripheral:(CBPeripheral * _Nonnull)peripheral didDiscoverCharacteristicsForService:(CBService * _Nonnull)service error:(NSError * _Nullable)error;
- (void)peripheral:(CBPeripheral * _Nonnull)peripheral didWriteValueForCharacteristic:(CBCharacteristic * _Nonnull)characteristic error:(NSError * _Nullable)error;
- (void)peripheral:(CBPeripheral * _Nonnull)peripheral didUpdateValueForCharacteristic:(CBCharacteristic * _Nonnull)characteristic error:(NSError * _Nullable)error;
@end


SWIFT_CLASS("_TtC11PBBluetooth11PBMFiDevice")
@interface PBMFiDevice : PBDevice
@end


SWIFT_CLASS("_TtC11PBBluetooth9PBMFiCard")
@interface PBMFiCard : PBMFiDevice
- (void)discoverServices;
@end


@interface PBMFiCard (SWIFT_EXTENSION(PBBluetooth))
- (void)peripheral:(CBPeripheral * _Nonnull)peripheral didDiscoverServices:(NSError * _Nullable)error;
- (void)peripheral:(CBPeripheral * _Nonnull)peripheral didDiscoverCharacteristicsForService:(CBService * _Nonnull)service error:(NSError * _Nullable)error;
- (void)peripheral:(CBPeripheral * _Nonnull)peripheral didWriteValueForCharacteristic:(CBCharacteristic * _Nonnull)characteristic error:(NSError * _Nullable)error;
- (void)peripheral:(CBPeripheral * _Nonnull)peripheral didUpdateValueForCharacteristic:(CBCharacteristic * _Nonnull)characteristic error:(NSError * _Nullable)error;
@end




SWIFT_CLASS("_TtC11PBBluetooth11PBMFiCardV2")
@interface PBMFiCardV2 : PBMFiCard
@end


SWIFT_CLASS("_TtC11PBBluetooth9PBMFiClip")
@interface PBMFiClip : PBMFiDevice
- (void)discoverServices;
- (void)peripheral:(CBPeripheral * _Nonnull)peripheral didDiscoverServices:(NSError * _Nullable)error;
- (void)peripheral:(CBPeripheral * _Nonnull)peripheral didDiscoverCharacteristicsForService:(CBService * _Nonnull)service error:(NSError * _Nullable)error;
- (void)peripheral:(CBPeripheral * _Nonnull)peripheral didWriteValueForCharacteristic:(CBCharacteristic * _Nonnull)characteristic error:(NSError * _Nullable)error;
@end





SWIFT_CLASS("_TtC11PBBluetooth11PBMFiClipV2")
@interface PBMFiClipV2 : PBMFiClip
@end



SWIFT_CLASS("_TtC11PBBluetooth11PBMFiR4KTag")
@interface PBMFiR4KTag : PBMFiClip
- (void)discoverServices;
@end



@interface PBMFiR4KTag (SWIFT_EXTENSION(PBBluetooth))
- (void)peripheral:(CBPeripheral * _Nonnull)peripheral didDiscoverServices:(NSError * _Nullable)error;
- (void)peripheral:(CBPeripheral * _Nonnull)peripheral didDiscoverCharacteristicsForService:(CBService * _Nonnull)service error:(NSError * _Nullable)error;
- (void)peripheral:(CBPeripheral * _Nonnull)peripheral didUpdateValueForCharacteristic:(CBCharacteristic * _Nonnull)characteristic error:(NSError * _Nullable)error;
@end



SWIFT_CLASS("_TtC11PBBluetooth8PBMFiTag")
@interface PBMFiTag : PBMFiCard
@end


SWIFT_CLASS("_TtC11PBBluetooth10PBMFiTagV2")
@interface PBMFiTagV2 : PBMFiTag
@end

#endif
#if defined(__cplusplus)
#endif
#if __has_attribute(external_source_symbol)
# pragma clang attribute pop
#endif
#pragma clang diagnostic pop
#endif

#else
#error unsupported Swift architecture
#endif
