//
//  ViewController.swift
//  Assignment1
//
//  Created by Yash Khandha on 12/8/18.
//  Copyright © 2018 Yash Khandha. All rights reserved.
//

/// Importing UIKit to handle event driven user interface
import UIKit
/// Importing Mapkit to access map and its functions
import MapKit
/// Importing CoreData to access the entities and properties linked with it
import CoreData
/// Importing core loacation to access the location directory
import CoreLocation
/// Importing AVFoundation to support audio visuals on the screen
import AVFoundation
/// Importing USerNotifications to support geofencing notifications
import UserNotifications

///HandleMapSearch protocol is used to manage the pin drop on selecting a location in the search bar to add animal
protocol HandleMapSearch {
    
    /// Method to be written in the Class implementing this Protocol
    /// - Parameter placemark: selected pin on the map
    func dropPinZoomIn(placemark:MKPlacemark)
}

/// ViewController class holds the map on the slave screen in split view controller
/// Referred www.raywenderlich.com tutorials
class ViewController: UIViewController, UpdateMapViewProtocol {
    
    var updatedBook: Animal?
    /// for setting the radious of scope on map
    let regionRadius: CLLocationDistance = 500
    /// list ot hold the animals from the coredata
    private var animalList: [Animal] = []
    /// creating managed object context instance to access the coredata
    private var managedObjectContext: NSManagedObjectContext
    /// instance of CLLcoationManager to access the methods of it in the functions
    let locationManager = CLLocationManager()
    /// for handling search bar on map view
    var resultSearchController:UISearchController? = nil
    /// to store the annotation details such as coordinate, title, subtitle
    var annotation: MKAnnotation?
    /// to save particular animal in the list of all animals
    var animalInList: Animal?
    /// to store the selected animal on the map
    var selectedAnimal: Animal?
    /// to store the status if animal is found in the list of animals in core data
    var animalFound: Bool
    /// to manage the audio on the home screen for animals
    var audioPlayer = AVAudioPlayer()
    /// mapView for the Map embedded in the slave controller of split view controller
    @IBOutlet weak var mapView: MKMapView!
    /// for dropping pin after search
    var selectedPin:MKPlacemark? = nil
    /// boolean to check if its a new animal
    var isNewAnimal: Bool
    /// to deal with geo fencing regions
    var geoLocation: CLCircularRegion?
    /// initialise circle renderer to draw circle around geofence
    var circleRenderer = MKCircleRenderer()
    
    /// initializer for Coredata
    ///
    /// - Parameter aDecoder: NSCoder instance for initialisation
    required init(coder aDecoder: NSCoder){
        
        /// to intialise the boolean value for animal found to false
        self.animalFound = false
        self.isNewAnimal = false
        /// appDelegate initialised to delegate of UIApplication
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        managedObjectContext = (appDelegate?.persistentContainer.viewContext)!
        super.init(coder: aDecoder)!
    }
    
    /// Method will be called when the view appears
    ///
    /// - Parameter animated: desc
    override func viewWillAppear(_ animated: Bool) {
        //self.definesPresentationContext = false
        self.audioPlayer.play()
        self.audioPlayer.setVolume(0.2, fadeDuration: 2.0)
        self.audioPlayer.numberOfLoops = 2
        
    }
    
    /// Method to load the initial view of the View Controller
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //initialising locationManager
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        //locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
        
        //to load the initial focus on the map at monash caulfield campus
        let initialLocation = CLLocation(latitude: -37.876823, longitude: 145.045837)
        centerMapOnLocation(location: initialLocation)
        
        //setting ViewController as delegate of MapView
        mapView.delegate = self
        
        //fetching the animals from the Animal Entity in core data
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Animal")
        do{
            /// animalist will hold all the animals stored in the Coredata
            animalList = try managedObjectContext.fetch(fetchRequest) as! [Animal]
            /// if the animal list is empty call the adddefaultAnimal method to add defualt list of animals in the core data
            if animalList.count == 0{
                addDefaultAnimalData()
                //now load the data form coredata and save it in the animal list
                animalList = try managedObjectContext.fetch(fetchRequest) as! [Animal]
            }
            /// for loop to select each animal from the list and plot it on the map view
            for animalInList in animalList{
                /// save the location coordinates in location variable to set it to the annotation
                let location = CLLocationCoordinate2DMake(animalInList.latitude, animalInList.longitude)
                
                //call the addAnnotation method on the mapView to add the newly created annotation on the map
                mapView.addAnnotation(animalInList)
                
                ///skip adding geolocation for user annotaiton
                /// Reference - www.devfright.com
                if !animalInList .isKind(of: MKUserLocation.self){
                    ///GEOLocation region details and identifier
                    geoLocation = CLCircularRegion(center: location, radius: 100, identifier: animalInList.name!)
                    geoLocation?.notifyOnEntry = true
                    geoLocation?.notifyOnExit = true
                    
                    locationManager.requestAlwaysAuthorization()
                    /// start geofencing monitoring
                    locationManager.startMonitoring(for: geoLocation!)
                    
                    /// to create geofence area around animal
                    let circle = MKCircle(center: location, radius: 100)
                    mapView.add(circle)
                }
            }
        }
        catch{
            fatalError("Failed to fetch animals: \(error)")
        }
        
        /// instance of LocationSearchTable to handle the search based on user entered value
        let locationSearchTable = storyboard!.instantiateViewController(withIdentifier: "LocationSearchTable") as! LocationSearchTable
        resultSearchController = UISearchController(searchResultsController: locationSearchTable)
        resultSearchController?.searchResultsUpdater = locationSearchTable
        
        /// to handle the searchbar and setting attributes for it
        let searchBar = resultSearchController!.searchBar
        searchBar.sizeToFit()
        searchBar.placeholder = "Search place to add animal"
        
        //setting the searchbar on the nav bar of the view
        navigationItem.titleView = resultSearchController?.searchBar
        resultSearchController?.hidesNavigationBarDuringPresentation = false
        resultSearchController?.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
        
        ///setting the mapView to the LocationSearchTable mapview instance
        locationSearchTable.mapView = mapView
        locationSearchTable.handleMapSearchDelegate = self
        
        /// to load the music file to be played on loading this page
        /// Reference - Youtube video by Jared Davidson
        do{
            //load the audio file from the Bundle
            audioPlayer = try AVAudioPlayer(contentsOf: URL.init(fileURLWithPath: Bundle.main.path(forResource: "Farm-sounds", ofType: "mp3")!))
            audioPlayer.prepareToPlay()
            ///to play the audio file
            audioPlayer.play()
        }
        catch{
            print(error)
        }
    }
    
    /// function abiding by UpdateMapViewProtocol to add annotation of newly added animal after animal is added and this screen is loaded
    ///
    /// - Parameter newAnimal: newly added animal
    func updateView(newAnimal: Animal) {
        mapView.addAnnotation(newAnimal)
        mapView.selectAnnotation(newAnimal, animated: true)
        
        ///adding geofence to newly added animal
        ///check if it is not user location. if it is then skip the geofence for user location
        if !newAnimal .isKind(of: MKUserLocation.self){
            ///GEOLocation details
            geoLocation = CLCircularRegion(center: newAnimal.coordinate, radius: 100, identifier: (newAnimal.name!))
            geoLocation?.notifyOnEntry = true
            geoLocation?.notifyOnExit = true
            
            locationManager.requestAlwaysAuthorization()
            locationManager.startMonitoring(for: geoLocation!)
            
            /// to add circular region around fence area
            let circle = MKCircle(center: newAnimal.coordinate, radius: 100)
            mapView.add(circle)
        }
    }
    
    
    /// This method is called when the system memory is low
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /// function to help focus on the regionradius around the lcoation coordinates received as a parameter
    /// - Parameter location: coordinates of location
    func centerMapOnLocation(location: CLLocation){
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, regionRadius, regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    /// This method helps to pass the coordinates to the centerMapOnLocation to focus around that region
    ///
    /// - Parameters:
    ///   - latitudeValue: latitude of location
    ///   - longitudeValue: longitude of location
    func focusOn(animal: Animal){
        self.mapView.centerCoordinate = animal.coordinate
        let annotation = animal as MKAnnotation
        /// title is set for annotation, however not displayed on selectannotation in mapview
        self.mapView.selectAnnotation(annotation, animated: true)
    }
    
    /// Fucntion to handle notifications for geofencing
    ///
    /// - Parameters:
    ///   - notificationText: text to display on the notification
    ///   - didEnter: boolean to identify if an area is entered
    func fireNotification(notificationText: String, didEnter: Bool) {
        let notificationCenter = UNUserNotificationCenter.current()
        
        notificationCenter.getNotificationSettings { (settings) in
            if settings.alertSetting == .enabled {
                let content = UNMutableNotificationContent()
                content.title = didEnter ? "We found some animals around you" : "See you soon"
                content.body = notificationText
                content.sound = UNNotificationSound.default()
                
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                
                let request = UNNotificationRequest(identifier: "Test", content: content, trigger: trigger)
                
                notificationCenter.add(request, withCompletionHandler: { (error) in
                    if error != nil {
                        // Handle the error
                    }
                })
            }
        }
    }
    
}

// MARK: - extension to handle map functions on this view
extension ViewController: MKMapViewDelegate {
    
    /// This method helps geenrate the mapview with the annotations
    ///
    /// - Parameters:
    ///   - mapView: mapView for the Map on the Controller
    ///   - annotation: point location of the animal
    /// - Returns: MKAnnotationView
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        /// saving the annotation as Animal type
        
        /// initialising view to MKAnnotationView to be used to plot it on the map
        var view: MKAnnotationView
        /// To hold the annotation view. If it is not empty execute this
        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: "AnnotationView") {
            dequeuedView.annotation = annotation
            view = dequeuedView
        } else {
            guard !annotation.isKind(of: MKUserLocation.self) else {
                
                let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "userLocation")
                annotationView.image = UIImage(named: "my-small-icon")
                return annotationView
            }
            ///prepare the view with the annotation details to be plotted on the map
            view = MKAnnotationView(annotation: annotation, reuseIdentifier: "AnnotationView")
            view.canShowCallout = true
            view.calloutOffset = CGPoint(x: -5, y: 5)
            /// to call the button view on clicking the annotation
            view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            
            /// To check if the annotation is a new animal or existing one. If it is a new one, add a basic marker on the map with MKMarkerAnnotationView
            if isNewAnimal == true{
                let annotation = annotation as? Animal
                
                let identifier = "marker"
                var view: MKMarkerAnnotationView
                
                view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.canShowCallout = true
                view.calloutOffset = CGPoint(x: -5, y: 5)
                view.isDraggable = true
                view.rightCalloutAccessoryView = UIButton(type: .contactAdd)
                isNewAnimal = false
                return view
            }
                /// if the animal is an existing one, just load the annoation with the custome annotation class created to store the icon along with other basic attributes of the annotation
            else {
                
                let annotaionWithImage = annotation as! Animal
                /// Check the breeed and assign icon accordingly to be viewd on map
                /// Reference - Stackoverflow hints 
                
                if annotaionWithImage.breed == "Kangaroo" {
                    let pinimage = UIImage(named: "kangaroo-icon-30x30")
                    view.image = pinimage
                }
                else if annotaionWithImage.breed == "Koala" {
                    let pinimage = UIImage(named: "koala-icon-30x30")
                    view.image = pinimage
                }
                else if annotaionWithImage.breed == "Rabbit" {
                    let pinimage = UIImage(named: "rabbit-icon-30x30")
                    view.image = pinimage
                }
                else if annotaionWithImage.breed == "Bear" {
                    let pinimage = UIImage(named: "bear-icon-30x30")
                    view.image = pinimage
                }
                else if annotaionWithImage.breed == "Gorilla" {
                    let pinimage = UIImage(named: "gorilla-icon-30x30")
                    view.image = pinimage
                }
                else if annotaionWithImage.breed == "Monkey" {
                    let pinimage = UIImage(named: "monkey-icon-30x30")
                    view.image = pinimage
                }
                else if annotaionWithImage.breed == "Other" {
                    let pinimage = UIImage(named: "other-30x30")
                    view.image = pinimage
                }
            }
        }
        return view
    }
    
    /// This method handles the annotation click for further action, based on whether animal exists already or not
    ///
    /// - Parameters:
    ///   - mapView: mapView
    ///   - view: view
    ///   - control: callOut control
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView,
                 calloutAccessoryControlTapped control: UIControl) {
        annotation = view.annotation
        
        /// refreshing the list to
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Animal")
        do{
            /// animalist will hold all the animals stored in the Coredata
            animalList = try managedObjectContext.fetch(fetchRequest) as! [Animal]
        }
        catch{
            fatalError("Unable to fetch list")
        }
        /// for loop to check if the annotation selected on the map for animal is already exisiting in the core data (list fetched  from core data) or its a new animal
        for animal in animalList{
            if animal.name == annotation?.title{
                /// set boolean value for animalFound to true if this animal already exists in the database
                animalFound = true
                /// assign the animal found to selectedAnimal for further action
                selectedAnimal = animal
            }
        }
        
        /// if the animal is not found, i.e. animal does not exist so performing segue operation to navigate to Add Animal Screen
        if animalFound == false{
            performSegue(withIdentifier: "addNewAnimal", sender: nil)
            view.reloadInputViews()
            mapView.removeAnnotation(annotation!)
        }
            /// if the animal already exists then navigate the annotation click to Animal details page
        else{
            performSegue(withIdentifier: "detailAnimal", sender: nil)
            /// set animalFound boolean to false, as to make the functionality working when user clicks again on any other map annotation
            animalFound = false
        }
    }
    
    /// Thiss method basically gets executed after the previous method to add si=ome contents with the performing segue to be accessed on the destination view
    ///
    /// - Parameters:
    ///   - segue: segue defined on the main storyboard
    ///   - sender: any
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        /// Get the new view controller using segue.destination. Pass the selected object to the detination view controller.
        /// to check if the destiantion is Add new animal or Detail animal using segue identifier
        if segue.identifier == "addNewAnimal"{
            let newAnimal = segue.destination as! AddAnimalViewController
            newAnimal.newAnimalAnnotation = annotation
            newAnimal.newAnimalDelegate = self
        }
        if segue.identifier == "detailAnimal"{
            let exisitingAnimal = segue.destination as! AnimalDetailViewController
            exisitingAnimal.animalDetail = selectedAnimal
            
        }
    }
    
    /// Method to draw geo fencing radius around the animal
    ///
    /// - Parameters:
    ///   - mapView: view
    ///   - overlay: overlay
    /// - Returns: renderer
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        circleRenderer = MKCircleRenderer(overlay: overlay)
        circleRenderer.strokeColor = UIColor.blue
        circleRenderer.lineWidth = 0.5
        return circleRenderer
    }   
    
    /// This function adds default animals in the core data if the list is empty when the app loads
    func addDefaultAnimalData(){
        
        /// Creating Animal instance and setting attribute values for default animal
        var animal = NSEntityDescription.insertNewObject(forEntityName: "Animal", into: managedObjectContext) as! Animal
        animal.name = "Hippy"
        animal.desc = "Hippy is a very innocent Koala"
        animal.breed = "Koala"
        animal.color = "Grey"
        animal.sex = "Male"
        animal.food = "Herbivore"
        animal.latitude = -37.8775713
        animal.longitude = 145.042254
        animal.imagePath = "koala-1"
        animal.iconPath = "koala-icon-30x30"
        
        /// Creating Animal instance and setting attribute values for default animal
        animal = NSEntityDescription.insertNewObject(forEntityName: "Animal", into: managedObjectContext) as! Animal
        animal.name = "Billy"
        animal.desc = "Bily loves to jump around everywhere"
        animal.breed = "Kangaroo"
        animal.color = "Tan Brown"
        animal.sex = "Female"
        animal.food = "Herbivore"
        animal.latitude = -37.8763322
        animal.longitude = 145.0415874
        animal.imagePath = "kroo-1"
        animal.iconPath = "kangaroo-icon-30x30"
        
        /// Creating Animal instance and setting attribute values for default animal
        animal = NSEntityDescription.insertNewObject(forEntityName: "Animal", into: managedObjectContext) as! Animal
        animal.name = "Pichu"
        animal.desc = "Pichu loves to meet strangers"
        animal.breed = "Monkey"
        animal.color = "Grey"
        animal.sex = "Male"
        animal.food = "Omnivore"
        animal.latitude = -37.8769717
        animal.longitude = 145.0454849
        animal.imagePath = "monkey-1"
        animal.iconPath = "monkey-icon-30x30"
        
        /// Creating Animal instance and setting attribute values for default animal
        animal = NSEntityDescription.insertNewObject(forEntityName: "Animal", into: managedObjectContext) as! Animal
        animal.name = "Kicksy"
        animal.desc = "Kicksy loves sunlight"
        animal.breed = "Rabbit"
        animal.color = "Red"
        animal.sex = "Female"
        animal.food = "Herbivore"
        animal.latitude = -37.8787473
        animal.longitude = 145.0400519
        animal.imagePath = "kroo-2"
        animal.iconPath = "rabbit-icon-30x30"
        
        /// Creating Animal instance and setting attribute values for default animal
        animal = NSEntityDescription.insertNewObject(forEntityName: "Animal", into: managedObjectContext) as! Animal
        animal.name = "Pitsburie"
        animal.desc = "Pitsburie is very friendly with other animals"
        animal.breed = "Rabbit"
        animal.color = "Grey"
        animal.sex = "Male"
        animal.food = "Herbivore"
        animal.latitude = -37.878105
        animal.longitude = 145.0442201
        animal.imagePath = "quokka-2"
        animal.iconPath = "merrkat-icon-30x30"
        
        do{
            /// Saving the contents created above to Core data
            try managedObjectContext.save()
        }
            
            /// to handle the error while saving to core data
        catch let error{
            print("Could not save Core data: \(error)")
        }
    }
}


//Extension class for CLLocationmanager functions
extension ViewController : CLLocationManagerDelegate {
    
    /// Fucntion to handle failures on accessing location and printing it on console
    ///
    /// - Parameters:
    ///   - manager: instance of CLLocationManager to manage the access
    ///   - error: description of error found
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("error:: \(error.localizedDescription)")
    }
    
    /// This function checks if the authorization of device is chnaged. And if its cnaged, it will ask for access again to the new user for usign locations
    ///
    /// - Parameters:
    ///   - manager: instance of CLLocationManager to manage the access
    ///   - status: current statud of use
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        //        if status == .authorizedWhenInUse {
        //            locationManager.requestLocation()
        //        }
        mapView.showsUserLocation = (status == .authorizedAlways)
    }
    
    /// This function is sued to navigate the map view to the user location.
    /// Commented as it can be used if any modifications needed later in the app
    /// - Parameters:
    ///   - manager: manager
    ///   - locations: location detail
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if locations.first != nil {
            //let span = MKCoordinateSpanMake(0.002, 0.002)
            /// Can be set to navigate to user location
            //let region = MKCoordinateRegion(center: (locations.first?.coordinate)!, span: span)
            //mapView.setRegion(region, animated: true)
        }
    }
    
    /// Function to access current user lcoation and changes to the location
    ///
    /// - Parameters:
    ///   - manager: manages location access
    ///   - region: region around to monitor
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        
        let alert = UIAlertController(title: "Animal detected", message: "You are near \(region.identifier). Check out and stay safe", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
        fireNotification(notificationText: "You are near \(region.identifier). Check out and stay safe", didEnter: true)
        
    }
    
    /// Function to check if the user has left the geofecing area
    ///
    /// - Parameters:
    ///   - manager: manages location access
    ///   - region: region around to monitor
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        let alert = UIAlertController(title: "See you soon", message: "\(region.identifier) will miss you. Come soon", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
        fireNotification(notificationText: "\(region.identifier) will miss you. Come soon", didEnter: false)
        }
    }

// MARK: -  To handle the pin drop on selecting a location from search locations item
// Tutorial referred for implementing this feature. Reference -> https://www.thorntech.com
extension ViewController: HandleMapSearch {
    func dropPinZoomIn(placemark:MKPlacemark){
        // cache the pin
        selectedPin = placemark
        // clear existing pins
        //mapView.removeAnnotations(mapView.annotations)
        /// set new animal sttaus to true
        isNewAnimal = true
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        annotation.title = placemark.name
        
        //setting the annotation attributes to be displayed on click
        if let city = placemark.locality,
            let state = placemark.administrativeArea {
            annotation.subtitle = "\(city) \(state)"
            annotation.subtitle = "Ohh. You found me! Click me to give shelter here"
        }
        mapView.addAnnotation(annotation)
        let span = MKCoordinateSpanMake(0.015, 0.015)
        let region = MKCoordinateRegionMake(placemark.coordinate, span)
        mapView.setRegion(region, animated: true)
        mapView.selectAnnotation(annotation, animated: true)
    }
}


// MARK: - To handle the seelcted animal in the list to help navigate on the map with focus on that animal
extension ViewController: AnimalSelectionDelegate{
    func animalSelected(_ newAnimal: Animal) {
        animalInList = newAnimal
    }
}
    
    /// This section has not been included in current implementation. But will be implemented in future
    /// Bsically, it helps to modify the pin and also giving directions on clicking the annotation
    
    ////for pin drop and action
    //extension ViewController : MKMapViewDelegate {
    //    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView?{
    //        if annotation is MKUserLocation {
    //            //return nil so map view draws "blue dot" for standard user location
    //            return nil
    //        }
    //        let reuseId = "pin"
    //        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
    //        pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
    //        pinView?.pinTintColor = UIColor.orange
    //        pinView?.canShowCallout = true
    //        let smallSquare = CGSize(width: 30, height: 30)
    //        let button = UIButton(frame: CGRect(origin: CGPoint.zero, size: smallSquare))
    //        button.setBackgroundImage(UIImage(named: "kangaroo-1"), for: .normal)
    //        button.addTarget(self, action: "getDirections", for: .touchUpInside)
    //        pinView?.leftCalloutAccessoryView = button
    //        return pinView
    //    }
    
    ///// to get directions on anntoation click
    //func getDirections(){
    //    if let selectedPin = selectedPin {
    //        let mapItem = MKMapItem(placemark: selectedPin)
    //        let launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
    //        mapItem.openInMaps(launchOptions: launchOptions)
    //    }
    //}
    //}


