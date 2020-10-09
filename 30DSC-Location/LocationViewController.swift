//
//  LocationViewController.swift
//  LocationFinder
//
//  Created by David Tran on 8/22/18.
//  Copyright © 2018 Wallie. All rights reserved.
//

import UIKit
import CoreLocation

class LocationViewController: UIViewController
{
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitutdeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var findLocationButton: UIButton!
    
    let locationManager = CLLocationManager()
    var location: CLLocation?
    var isUpdatingLocation = false
    var lastLocationError: Error?
    
    //geocoder
    let geocoder = CLGeocoder()
    var placemark: CLPlacemark?
    var isPerformingReverseGeocoding = false
    var lastGeocodingError: Error?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateUI()
    }
    
    func updateUI() {
        if let location = location {
            latitudeLabel.text = String(format: "%.8f", location.coordinate.latitude)
            longitutdeLabel.text = String(format: "%.8f", location.coordinate.longitude)
            statusLabel.text = "New Location Detected!"
            
            if let placemark = placemark {
                addressLabel.text = getAddress(from: placemark)
            } else if isPerformingReverseGeocoding {
                addressLabel.text = "Searching for address..."
            } else if lastGeocodingError != nil {
                addressLabel.text = "Error finding a valid address"
            } else {
                addressLabel.text = "address not found"
            }
        } else {
            statusLabel.text = "Tap 'Find Location' to start"
            latitudeLabel.text = "-"
            longitutdeLabel.text = "-"
            addressLabel.text = "-"
        }
    }
    
    func getAddress(from placemark: CLPlacemark) -> String {
        // 123 Test Street
        // CityName, State ZipCode
        // Country
        
        var line1 = ""
        if let street1 = placemark.subThoroughfare {
            line1 += street1 + " "
        }
        if let street2 = placemark.thoroughfare {
            line1 += street2
        }
        var line2 = ""
        if let city = placemark.locality {
            line2 += city + ", "
        }
        if let stateOrProvince = placemark.administrativeArea {
            line2 += stateOrProvince + " "
        }
        if let postalCode = placemark.postalCode {
            line2 += postalCode
        }
        
        var line3 = ""
        if let country = placemark.country {
            line3 += country
        }
        
        return line1 + "\n" + line2 + "\n" + line3
    }
    
    // MARK: - Target / Actions
    
    @IBAction func findLocationDidTap(_ sender: Any) {
        //1. get the user's permission to use location services
        let authorizationStatus = CLLocationManager.authorizationStatus()
        if authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
            return
        }
                
        //2. report to user if permission is denied - (1) user accidentally refused (2) the device is restricted
        if authorizationStatus == .denied || authorizationStatus == .restricted {
            reportLocationServicesDenierdError()
            return
        }
        
        //3. start / stop finding location
        if isUpdatingLocation {
            stopLocationManager()
        } else {
            location = nil
            lastLocationError = nil
            
            placemark = nil
            lastGeocodingError = nil
            
            startLocationManager()
        }
        
        updateUI()
    }
    
    //MARK: - Helper functions
    
    func reportLocationServicesDenierdError() {
        let alert = UIAlertController(title: "Ooops! Location Services Disabled", message: "Please go to Settings > Privacy to enable location services for this app", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    
    func stopLocationManager() {
        if isUpdatingLocation {
            locationManager.stopUpdatingLocation()
            locationManager.delegate = nil
            isUpdatingLocation = false
        }
    }
    
    func startLocationManager() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            locationManager.startUpdatingLocation()
            isUpdatingLocation = true
        }
    }
    
}

// MARK : - CLLocationManagerDelegate

extension LocationViewController : CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("ERROR!! locationManager didFailWithError: \(error)")
        if (error as NSError).code == CLError.locationUnknown.rawValue {
            return
        }
        lastLocationError = error
        stopLocationManager()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last!
        stopLocationManager()
        updateUI()
        
        if location != nil {
            if !isPerformingReverseGeocoding {
                print("**** start performing Geocoding...")
                isPerformingReverseGeocoding = true
                
                geocoder.reverseGeocodeLocation(location!) { (placemarks, error) in
                    self.lastGeocodingError = error
                    if error == nil, let placemarks = placemarks, !placemarks.isEmpty {
                        self.placemark = placemarks.last!
                    } else {
                        self.placemark = nil
                    }
                    
                    self.isPerformingReverseGeocoding = false
                    self.updateUI()
                }
            }
        }
        
    }
}
