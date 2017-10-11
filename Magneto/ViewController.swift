//
//  ViewController.swift
//  Magneto
//
//  Created by Felix M. on 06.10.17.
//  Copyright © 2017 Felix M. All rights reserved.
//

import UIKit

// CoreMotion Framework is needed (holds all sensores like accelerometer, gyroscope, pedometer, and environment-related events (magnetometer etc)
import CoreMotion

class ViewController: UIViewController {
    
    // The CMMotionManager can start all CoreMition Sensors
    let motionManager = CMMotionManager()
    
    // needed for update scheduled method calls
    var timer: Timer!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // start the Magnetometer Sensor
        motionManager.startMagnetometerUpdates()
        
        // start the timer with a repeating method call with a timeout of 100ms
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(ViewController.update), userInfo: nil, repeats: true)

    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // method that gets called from timer
    @objc func update() {
        // check wether Magnetometer exists and has some data for us
        if let magnetometerData = motionManager.magnetometerData {
            // prints CoreData from Magnetometer Sensor -> x vector force :: y vector force :: z vector force :: @ timestamp
            print(magnetometerData)
        }
    }

}

