//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by Tony Buckner on 5/7/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MainViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var appendDeleteSwitch: UISwitch!
    
    //delete switch
    //var deletePins = false
    
    //selected index path for fetched results data
    var selectedIndex = IndexPath()
    
    //data controller code and fetch requests
    var dataController:DataController!
    
    //fetched results variable and function
    var fetchedResultsController:NSFetchedResultsController<Pin>!
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        //fetchedResultsController.delegate = self
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self as? NSFetchedResultsControllerDelegate
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    //------------------------------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //change swich off color
        appendDeleteSwitch.backgroundColor = UIColor.red
        appendDeleteSwitch.layer.cornerRadius = 16.0
        
        mapView.delegate = self
        
        //press and hold variable
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPress))
        gestureRecognizer.minimumPressDuration = 0.5
        gestureRecognizer.delegate = self as? UIGestureRecognizerDelegate
        mapView.addGestureRecognizer(gestureRecognizer)
        //-----------------------
        
        setupFetchedResultsController()
        loadPins()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupFetchedResultsController()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //place and refreshing code here
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //------------------------------Pin and annotation functions--------------------------
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.animatesDrop = true
            pinView!.setSelected(true, animated: true)
            pinView!.pinTintColor = .purple
            pinView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: nil))
        }
        else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    //these make pin taps run functions
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        if appendDeleteSwitch.isOn{
            
            view.setSelected(false, animated: true)
            mapView.selectAnnotation(view.annotation!, animated: true)
            
            print("Selected...")
            
            //set coordinates to be sent to next view
            SharedPinInformation.sharedInstance.info.latitude = (view.annotation?.coordinate.latitude)!
            SharedPinInformation.sharedInstance.info.longitude = (view.annotation?.coordinate.longitude)!
            
            //go thru array to get the index path for segue
            var place = 0
            while place < (fetchedResultsController.sections?[0].numberOfObjects)!{
                let results = fetchedResultsController.object(at: IndexPath(row: place, section: 0))
                if (view.annotation?.coordinate.latitude == results.latitude) && (view.annotation?.coordinate.longitude == results.longitude){
                    selectedIndex = IndexPath(row: place, section: 0)
                }
                place += 1
            }
            
            performSegue(withIdentifier: "LocationPictures", sender: nil)
            
        } else {
            //delete pin from core data and from visible map
            deletePin(pinLat: (view.annotation?.coordinate.latitude)!, pinLong: (view.annotation?.coordinate.longitude)!)
            mapView.removeAnnotation(view.annotation!)
        }
        
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        view.setSelected(false, animated: true)
        print("DeSelected...")
    }
    
    //long press function
    @objc func longPress(gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .recognized{ //.ended
            
            if appendDeleteSwitch.isOn{
                
                let touchLocation = gestureRecognizer.location(in: mapView)
                let locationCoordinate = mapView.convert(touchLocation, toCoordinateFrom: mapView)
                let coordinate = locationCoordinate
                print("Tapped at lat: \(locationCoordinate.latitude) long: \(locationCoordinate.longitude)")
                
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate
                
                //this will save the instance when the pin is tapped
                let pin = Pin(context: dataController.viewContext)
                pin.longitude = locationCoordinate.longitude
                pin.latitude = locationCoordinate.latitude
                pin.creationDate = Date()
                try? dataController.viewContext.save()
                //---------------------------------------------------
                
                mapView.addAnnotation(annotation)
            }
            setupFetchedResultsController()
        }
    }
    
    //loads pins at the start of the app
    func loadPins() {
        
        var place = 0
        
        while place < (fetchedResultsController.sections?[0].numberOfObjects)!{
            
            //iterate through fetched data
            let results = fetchedResultsController.object(at: IndexPath(row: place, section: 0))
            
            //add pin
            let annotation = MKPointAnnotation()
            annotation.coordinate.latitude = results.latitude
            annotation.coordinate.longitude = results.longitude
            mapView.addAnnotation(annotation)
            
            //go to next array element
            place += 1
        }
    }
    
    //delete pin function when deleteSwitch is ON
    func deletePin(pinLat: Double, pinLong: Double){
        //dataController.viewContext.reset()
        //try? dataController.viewContext.save()
        
        print(fetchedResultsController.sections?[0].numberOfObjects as Any)
        print("-------------------------------------")
        
        //iteration variable
        var place = 0
        //array iteration
        while place < (fetchedResultsController.sections?[0].numberOfObjects)!{
            
            //iterate through fetched data
            let results = fetchedResultsController.object(at: IndexPath(row: place, section: 0))
            
            print(results.latitude)
            print(pinLat)
            print(results.longitude)
            print(pinLong)
            
            if (pinLat == results.latitude) && (pinLong == results.longitude){
                
                //delete from core data
                let pinToDelete = fetchedResultsController.object(at: IndexPath(row: place, section: 0))
                
                dataController.viewContext.delete(pinToDelete)
                try? dataController.viewContext.save()
                
            }
            
            //go to next array element
            place += 1
            
        }
    }
    
    //send info over to next VC
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? LocationPicturesViewController {
            
            print(mapView.selectedAnnotations[0].coordinate.latitude)
            print(mapView.selectedAnnotations[0].coordinate.longitude)
            
            var place = 0
            while place < (fetchedResultsController.sections?[0].numberOfObjects)!{
                let results = fetchedResultsController.object(at: IndexPath(row: place, section: 0))
                if (mapView.selectedAnnotations[0].coordinate.latitude == results.latitude) && (mapView.selectedAnnotations[0].coordinate.longitude == results.longitude){
                    
                    //send found pin
                    vc.pin = fetchedResultsController.object(at: IndexPath(row: place, section: 0))
                    
                }
                place += 1
            }
            
            vc.dataController = dataController
            
        }
    }
}









