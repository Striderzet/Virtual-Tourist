//
//  LocationPicturesViewController.swift
//  Virtual Tourist
//
//  Created by Tony Buckner on 5/21/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import Foundation
import MapKit
import UIKit
import CoreData

//PLEASE REMEMBER THESE SUPER CLASSES!!
class LocationPicturesViewController:UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    //reload flag for the fetched results
    var reloadFlag = 1
    
    //array for pictures
    var pitctureArray = [UIImage?]()
    var testImage = UIImage()
    
    //var from Data model
    var pin: Pin!
    
    //data controller varible to hold from the appdelegate
    var dataController:DataController!
    
    //fetched results controller
    var fetchedResultsController:NSFetchedResultsController<Photo>!
    
    //lat long variables
    var lat = Double()
    var long = Double()
    
    //collection size
    var collSize = 21
    
    fileprivate func setupFetchedResultsController() {
        //fetch request
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        
        //predicate creation to check for current pin
        let predicate = NSPredicate(format: "pin == %@", self.pin)
        
        //set predicate property for fetch request
        fetchRequest.predicate = predicate
        
        //sort by date with a sort descriptor
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: true)
        
        //set sort descriptor property
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        fetchedResultsController.delegate = self as? NSFetchedResultsControllerDelegate
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("ERROR! \(error.localizedDescription)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
        //add new pin
        let annotation = MKPointAnnotation()
        
        annotation.coordinate.latitude = SharedPinInformation.sharedInstance.info.latitude
        lat = annotation.coordinate.latitude
        
        annotation.coordinate.longitude = SharedPinInformation.sharedInstance.info.longitude
        long = annotation.coordinate.longitude
        
        mapView.addAnnotation(annotation)
        
        //zoom into location for coordinates
        let span = MKCoordinateSpanMake(10.00, 10.00)
        let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude), span: span)
        mapView.setRegion(region, animated: false)
        
        setupFetchedResultsController()
        
        collectionView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupFetchedResultsController()
        
        if let indexPath = collectionView.indexPathsForSelectedItems {
            //collectionView.deselectItem(at: indexPath, animated: false)
            collectionView.reloadItems(at: indexPath)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        setupFetchedResultsController()
        
        if let indexPath = collectionView.indexPathsForSelectedItems {
            //collectionView.deselectItem(at: indexPath, animated: false)
            collectionView.reloadItems(at: indexPath)
        }
    }
    
    //pin drop function
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.animatesDrop = true
            pinView!.pinTintColor = .purple
        }
        else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    //Collection view functions-----------------------------------------------------------
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        //#warning Incomplete method implementation -- Return the number of sections
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print(fetchedResultsController.sections?[section].numberOfObjects as Any)
        
        if fetchedResultsController.sections?[0].numberOfObjects == 0 {
            return collSize
        } else {
            collSize = (fetchedResultsController.sections?[0].numberOfObjects)!
            return collSize
        }
        
    }
    
    internal func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        //initiate cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PictureCell", for: indexPath) as! CollectionViewCell
        cell.backgroundColor = UIColor.gray
        
        //This is no longer needed but i have saved it here just to compare the new function
        //1. this is where the array gets checked for value so cells dont reload when scrolling
        /*if let finalImage = pitctureArray[safe: indexPath.row]{
            
            print("Image will load from array when scrolled, and not downloaded again")
            cell.cellImage?.image = finalImage
            //return cell
            
        } else*/
        
        if indexPath.row >= (fetchedResultsController.fetchedObjects?.count)! {
        
            //2. this is where i want to check if the element is empty, and when the images get loaded from the internet, they will save to the array, never to be loaded again
            
            cell.activityIndicator.startAnimating()
            
            //calls function to dowmload images and populate them to the cell one at a time
            FAPIFunctions.searchByLatLon(lat: SharedPinInformation.sharedInstance.info.latitude, long: SharedPinInformation.sharedInstance.info.longitude) { GO, image in
                
                //soft save to local cache
                self.pitctureArray.append(image)
                
                performUIUpdatesOnMain {
                    if GO{
                        
                        //save to cell image
                        cell.cellImage.image = image
                        
                        //hard save to core data
                        let photo = Photo(context: self.dataController.viewContext)
                        let imageData: Data? = UIImagePNGRepresentation(image)
                        //let imageData: Data = UIImagePNGRepresentation(image)! as Data
                        photo.pic = imageData
                        photo.creationDate = Date()
                        photo.pin = self.pin
                        photo.hasImage = true
                        try? self.dataController.viewContext.save()
                        //---------------------------------------------------
                        
                        print(self.reloadFlag)
                        self.reloadFlag += 1
                        
                        cell.activityIndicator.stopAnimating()
                    }
                }
            }
        } else {
            
            print(indexPath)
            
            //hard load from core data
            let finalImage = fetchedResultsController.object(at: indexPath)
            cell.cellImage.image = UIImage(data:finalImage.pic! ,scale:1.0)
            
            //soft load from local cache
            /*if let finalImage = imageCache[indexPath.row] as? UIImage{
             cell.cellImage.image = finalImage
             }*/
            
        }
        
        /*if reloadFlag == fetchedResultsController.sections?[0].numberOfObjects{
            setupFetchedResultsController()
        }*/
        
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        //reduce size by one
        collSize -= 1
        
        //delete from core data
        let picToDelete = fetchedResultsController.object(at: indexPath)
        dataController.viewContext.delete(picToDelete)
        try? dataController.viewContext.save()
        setupFetchedResultsController()
        print(fetchedResultsController.sections?[0].numberOfObjects as Any)
        
        //delete from collection and reload
        self.collectionView!.deleteItems(at: [indexPath])
        self.pitctureArray.removeAll()
        self.collectionView.reloadData()
        
    }
    
    @IBAction func reloadPics(_ sender: Any) {
        
        //reduce size initially
        collSize -= 1
        
        //go thru all of the saved pics and delete them one by one
        while collSize > -1 {
            
            //delete from core data
            let picToDelete = fetchedResultsController.object(at: IndexPath(row: collSize, section: 0))
            dataController.viewContext.delete(picToDelete)
            
            collSize -= 1
        }
        
        //save current changes and reset array
        try? dataController.viewContext.save()
        self.pitctureArray.removeAll()
        
        //reset view size and reload data
        collSize = 21
        collectionView.reloadData()
        
    }
    
}

//this function bypasses the out of bounds error for an array.
extension Collection {
    /// Returns the element at the specified index within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}


//this is here to update the data when loaded so it can be deleted as soon as it is saved.
extension LocationPicturesViewController: NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type{
        case .insert:
            //tableView.insertRows(at: [newIndexPath!], with: .fade)
            //collectionView.insertItems(at: [newIndexPath!])
            break
        case .delete:
            //tableView.deleteRows(at: [indexPath!], with: .fade)
            //collectionView.deleteItems(at: [newIndexPath!])
            break
        case .update:
            //tableView.reloadRows(at: [indexPath!], with: .fade)
            //collectionView.reloadItems(at: [newIndexPath!])
            break
        case .move:
            //tableView.moveRow(at: indexPath!, to: newIndexPath!)
            //collectionView.moveItem(at: indexPath!, to: newIndexPath!)
            break
        }
    }
}


