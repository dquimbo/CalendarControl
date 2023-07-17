//
//  PBBroadcastManager.swift
//  Pebblebee
//
//  Created by Jon Vogel on 3/15/16.
//  Copyright © 2016 Pebblebee. All rights reserved.
//

///The `PBBroadcastManager` is mostly used internally. However, you should call the shared instances' `.stopLocalBeacon(_ sender: AnyObject)` function in your `appDidEnterBackground` app delegate class.
import Foundation
import CoreBluetooth
import CoreLocation

open class PBBroadcastManager: NSObject {
    ///The shared instance of the 'PBBroadcastManager'
    public static let shared: PBBroadcastManager = PBBroadcastManager()
    //The beacon region object. Where the major and minor get configure
    @objc var beaconRegion: CLBeaconRegion!
    //The data that gets used to broadcast the signal
    @objc var beaconPeripheralData: [String: AnyObject]!
    //The peripheral manager that will get built up and torn down when told to start and stop broadcasting
    @objc var peripheralManager: CBPeripheralManager?
    //Internal function to set up the beacon. Will broadcast the passed major and minor values.
    @objc func setUpBeacon(withMajor major: Int, withMinor minor: Int, withQueue: DispatchQueue?) {
        //If the beacon region is not nil then tear it down so we can start fresh
        if self.beaconRegion != nil {
            self.stopLocalBeacon(self)
        }
        
        //Re-instantiate the peripheral manager
        self.peripheralManager = CBPeripheralManager(delegate: self, queue: withQueue)
        //Re-instantiate the Beacon Region
        self.beaconRegion = CLBeaconRegion(proximityUUID: beaconUUID, major: UInt16(major), minor: UInt16(minor), identifier: beaconSignalName)
        //Set the delegate to self
        self.peripheralManager?.delegate = self
        //See if we can get the data from the current beacon region
        
        guard let data = self.beaconRegion.peripheralData(withMeasuredPower: nil) as? [String: AnyObject] else {
            return
        }
        //If we can then assign it to the classes object to keep track of it
        self.beaconPeripheralData = data
    }
    
    @objc public func requestAuthorization(withQueue: DispatchQueue?) {
        self.peripheralManager = CBPeripheralManager(delegate: self, queue: withQueue)
        self.peripheralManager = nil
    }
    
    /**
     This function shuts down all phone iBeacon broadcasting. We recommnd that you call this in your 'applicationDidEnterBackground' function. Continiously running the braodcast manager in the background will reduce battery life and will cause some devices to behave unexpectidly when the app is brought to the active state.
     
     -Paramaters:
     -sender: The object that is requesting the iBeacon signal to be shut down.
    */
    @objc public func stopLocalBeacon(_ sender: AnyObject) {
        //Tell the peripheral manager to stop advertising
        peripheralManager?.stopAdvertising()
        //Set the peripheral manager to nil
        peripheralManager = nil
        //Set data to nil
        //beaconPeripheralData = nil
        //Set the broadcast region to nil
        beaconRegion = nil
    }
    
    @objc internal func startLocalBeacon() {
        if self.peripheralManager?.state != CBManagerState.poweredOn {
            self.peripheralManager?.startAdvertising(self.beaconPeripheralData)
        }
    }
    
    

}


extension PBBroadcastManager: CBPeripheralManagerDelegate {
    
    //Delegate funciton that gets called when the state of the broadcast manager changes.
    public func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case CBManagerState.poweredOn:
            peripheralManager?.startAdvertising(self.beaconPeripheralData)
        @unknown default:
            break
        }
    }
    

    
}
