//
//  DriverTableViewController.swift
//  UberClone
//
//  Created by Dean Lindsey on 06/03/2018.
//  Copyright © 2018 Dean Lindsey. All rights reserved.
//

import UIKit
import MapKit
import FirebaseAuth
import FirebaseDatabase

class DriverTableViewController: UITableViewController, CLLocationManagerDelegate {
    
    var rideRequests : [FIRDataSnapshot] = []
    var locationManager = CLLocationManager()
    var driverLocation = CLLocationCoordinate2D()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        FIRDatabase.database().reference().child("RideRequests").observe(.childAdded) { (snapshot) in
            
            if let rideRequestDict = snapshot.value as? [String:AnyObject] {
                if let driverlat = rideRequestDict["driverLat"] as? Double {
                    
                } else {
                    self.rideRequests.append(snapshot)
                    self.tableView.reloadData()
                }
            }
        }
        
        // Timer to update drivers location and work out distance
        Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { (timer) in
            self.tableView.reloadData()
        }
        // Timer
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let coord = manager.location?.coordinate {
            driverLocation = coord
        }
    }
    
    @IBAction func logOutTapped(_ sender: Any) {
        try? FIRAuth.auth()?.signOut()
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return rideRequests.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "rideRequestCell", for: indexPath)
        
        let snapshot = rideRequests[indexPath.row]
        
        if let rideRequestDict = snapshot.value as? [String:AnyObject] {
            if let email = rideRequestDict["email"] as? String {
                
                if let lat = rideRequestDict["lat"] as? Double {
                    if let lon = rideRequestDict["lon"] as? Double {
                        
                        let driverCLLocation = CLLocation(latitude: driverLocation.latitude, longitude: driverLocation.longitude)
                        let riderCLLocation = CLLocation(latitude: lat, longitude: lon)
                        
                        let distance = driverCLLocation.distance(from: riderCLLocation) / 1000
                        let roundedDistance = round(distance * 100) / 100
                        
                        cell.textLabel?.text = "\(email) - \(roundedDistance) km away"
                    }
                }
            }
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let snapshot = rideRequests[indexPath.row]
        performSegue(withIdentifier: "acceptSegue", sender: snapshot)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let acceptVC = segue.destination as? AcceptRequestViewController {
            
            if let snapshot = sender as? FIRDataSnapshot {
                
                if let rideRequestDict = snapshot.value as? [String:AnyObject] {
                    if let email = rideRequestDict["email"] as? String {
                        
                        if let lat = rideRequestDict["lat"] as? Double {
                            if let lon = rideRequestDict["lon"] as? Double {
                                acceptVC.requestEmail = email
                                let location = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                                acceptVC.requestLocation = location
                                acceptVC.driverLocation = driverLocation
                            }
                        }
                    }
                }
            }
        }
    }
}
