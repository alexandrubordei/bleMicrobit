//
//  ViewController.swift
//  BLEtest
//
//  Created by Alexandru Bordei on 1/11/18.
//  Copyright © 2018 Alexandru Bordei. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class MainViewController: UIViewController,
CLLocationManagerDelegate, MKMapViewDelegate, MicrobitDelegate{
    
    let microbit = Microbit()
    
    let locationManager = CLLocationManager()
    
    var lastLocation:CLLocationCoordinate2D?
    var destinationCompletion: MKLocalSearchCompletion?
    var destination: MKMapItem?
    var originalDurationEstimate: TimeInterval?
    var currentDurationEstimate: TimeInterval?
    

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var StatusLabel: UILabel!
   
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.microbit.delegate = self
        self.mapView.delegate = self
        
        locationManager.requestAlwaysAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
        
        if(self.destinationCompletion != nil)
        {
            searchForPlaceAndCenterMap(completion: self.destinationCompletion!)
        }
    }
    
    
    func microbitDidUpdateStatus(status: String) {
        StatusLabel.text = status
    }
    
    
    //function that updates the position on the external bargraph
    //between 0 and 24
    func setProgress(progress: Int){
        microbit.uartSend(message: String(format: "%.0f\n", progress))
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        
        lastLocation = locValue
        
        self.mapView.setCenter(locValue, animated: true)
    }
    
    
    func searchForPlaceAndCenterMap(completion: MKLocalSearchCompletion){
        let request = MKLocalSearch.Request(completion: completion)
        
        request.region = self.mapView.region
        
        // Use the network activity indicator as a hint to the user that a search is in progress.
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        let localSearch = MKLocalSearch(request: request)
        
        localSearch.start { [weak self] (response, error) in
            guard error == nil else {
                
                let alert = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: .alert)
                
                alert.addAction(UIAlertAction(title: "Oh! Bummer!", style: .default, handler: nil))
                self!.present(alert, animated: true)
            
                return
            }
            
            if(response!.mapItems.count>0)
            {
                self!.destination = response!.mapItems[0]
                
                self!.mapView.setCenter(self!.destination!.placemark.coordinate, animated: true)
                
                let destinationPointAnnotation = MKPointAnnotation()
                destinationPointAnnotation.title = self!.destination!.placemark.title
                destinationPointAnnotation.coordinate = self!.destination!.placemark.coordinate
                self!.mapView.addAnnotation(destinationPointAnnotation)
            }
            
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
    }
    
    func getDrivingDirections(source: MKPlacemark, destination: MKPlacemark)
    {
        let request = MKDirectionsRequest()
        
        request.source      = MKMapItem(placemark: source)
        request.destination = MKMapItem(placemark: destination)
        
        // Specify the transportation type
        request.transportType = MKDirectionsTransportType.automobile;
        
        // If you're open to getting more than one route,
        // requestsAlternateRoutes = true; else requestsAlternateRoutes = false;
        request.requestsAlternateRoutes = false
        
        let directions = MKDirections(request: request)
        
        // Now we have the routes, we can calculate the distance using
        directions.calculate { (response, error) in
            if let response = response, let route = response.routes.first {
                let estimate =  route.expectedTravelTime // You could have this returned in an async approach
                if(self.originalDurationEstimate==nil){
                    self.originalDurationEstimate = estimate
                }
                else
                {
                    self.currentDurationEstimate = estimate
                }
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is MKPointAnnotation else { return nil }
        
        let identifier = "DestinationPin"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView!.canShowCallout = true
           
        } else {
            annotationView!.annotation = annotation
        }
        
       
        
        return annotationView
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.destination is SearchViewController
        {
            let vc = segue.destination as? SearchViewController
            
            vc!.region = self.mapView.region
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func log(_ text:String)
    {
        print(text+"\r\n")
        
    }
    
    


}

