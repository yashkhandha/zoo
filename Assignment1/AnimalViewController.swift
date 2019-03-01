//
//  AnimalViewController.swift
//  Assignment1
//
//  Created by Yash Khandha on 17/8/18.
//  Copyright © 2018 Yash Khandha. All rights reserved.
//

/// Importing UIKit to handle event driven user interface
import UIKit
/// Importing CoreData to access the entities and attributes linked with it
import CoreData
/// Importing MaPkit
import MapKit

//to update on slave from master potrait

/// Protocol used to handle the animal selection on the master and redirect to Slave (Split View controller)
protocol AnimalSelectionDelegate: class {
    func animalSelected(_ newAnimal: Animal)
}

/// This class handles the list of all animals with UITableViewController overridden functions
/// UITableViewController : To manage the table and list and related operations
/// UISearchResultsUpdating : To implement search in list and update the list interactively
/// UISearchBarDelegate : To implement the search bar
/// CLLocationManagerDelegate: To receive events relating to geo fences
/// Referred www.raywenderlich.com tutorials
class AnimalViewController: UITableViewController, UISearchResultsUpdating, UISearchBarDelegate, CLLocationManagerDelegate {

    /// list ot hold animal details from core data
    private var animalList: [Animal] = []
    /// list to hold filtered data on search
    private var filteredAnimalList: [Animal] = []
    /// creating link to the managed object context in core data
    private var managedObjectContext: NSManagedObjectContext
    /// instance of ViewController class to access its attributes
    var viewController: ViewController?
    /// to handle the animal selection on the master and redirect to Slave (Split View controller)
    weak var delegate: AnimalSelectionDelegate?
    /// To store the path for all images in core data
    var imagePathList = [String]()
    /// intitializing the variables to be used in table view cell to assign values
    private let SECTION_BOOKS = 0
    private let SECTION_COUNT = 1
    /// to save the indexpath for cell to be deleted in table view
    var deleteAnimalIndexPath: IndexPath? = nil
    
    /// initializer for Coredata
    required init(coder aDecoder: NSCoder){
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        managedObjectContext = (appDelegate?.persistentContainer.viewContext)!
        super.init(coder: aDecoder)!
    }

    /// To load the animals from core data to the list and display on the screen
    override func viewDidLoad() {
        super.viewDidLoad()
        /// to fix the nav bar when navigating back to this page
        //self.definesPresentationContext = true

        /// intitialising the fetch request with the entity saved in the project
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName:"Animal")
        do{
            /// load the list using fetch function and above request
            animalList = try managedObjectContext.fetch(fetchRequest) as! [Animal]
            /// sort the initial list A->Z
            animalList.sort(by:{$0.name!.lowercased() < $1.name!.lowercased()})
        }
        catch{
            fatalError("Failed to fetch animals: \(error)")
        }
        
        /// laod the filteredAnimalList to animalList to perform filtering on list on search
        filteredAnimalList = animalList;
        
        /// search related proeprties
        let searchController = UISearchController(searchResultsController: nil);
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Click to Search/Filter animals"
        searchController.searchBar.autocapitalizationType = .none
        
        navigationItem.searchController = searchController
        searchController.searchBar.sizeToFit()
        
        searchController.searchBar.scopeButtonTitles = ["Sort A-Z", "Sort Z-A"]
        searchController.searchBar.delegate = self
        
        /// to preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = true        
    }
    
    /// Function will be cllaed whenever the screen will be loaded
    ///
    /// - Parameter animated: boolean to add or not add animations
    override func viewWillAppear(_ animated: Bool) {
        
        /// stop the background music
        self.viewController?.audioPlayer.play()
        self.viewController?.audioPlayer.setVolume(0.2, fadeDuration: 1.0)
        self.viewController?.audioPlayer.numberOfLoops = 2
        
        //coredata fetching the list
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName:"Animal")
        do{
            animalList = try managedObjectContext.fetch(fetchRequest) as! [Animal]
            animalList.sort(by:{$0.name!.lowercased() < $1.name!.lowercased()})
        }
        catch{
            fatalError("Failed to fetch animals: \(error)")
        }
        filteredAnimalList = animalList;
    }
    
    /// to check if memory is full
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    /// Method gives the number of sections to be displayed on the lsit
    ///
    /// - Parameter tableView: table view
    /// - Returns: number of sections
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }
    
    /// Method gives the number of rows in each section defined above
    ///
    /// - Parameters:
    ///   - tableView: table view
    ///   - section: section in the view
    /// - Returns: number of rows to display in each section
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if(section == SECTION_COUNT){
            return 1
        }
        return filteredAnimalList.count
    }
    
    /// Method to set the values in the cells at each row
    ///
    /// - Parameters:
    ///   - tableView: table view
    ///   - indexPath: integer value of row number
    /// - Returns: cell
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cellResuseIdentifier = "AnimalCell"
        if indexPath.section == SECTION_COUNT {
            cellResuseIdentifier = "TotalCell"
        }
        /// set the cell with the selected indexpath
        let cell = tableView.dequeueReusableCell(withIdentifier: cellResuseIdentifier, for: indexPath)
        
        /// Configuring the cell
        if indexPath.section == SECTION_BOOKS {
            let animalCell = cell as! AnimalTableViewCell
            animalCell.animalName.text = filteredAnimalList[indexPath.row].name
            animalCell.animalDescription.text = filteredAnimalList[indexPath.row].desc
            /// To check is the path length for image is greater than particular value to differentiate to load image from assets(for default animals) or core data(newly added animals)
            if (filteredAnimalList[indexPath.row].imagePath?.count)! > 9 {
                /// load image from core data
                animalCell.animalImage.image = loadImageData(fileName: filteredAnimalList[indexPath.row].imagePath!)
            }
            else{
                /// load the image from assets
                animalCell.animalImage.image = UIImage(named: filteredAnimalList[indexPath.row].imagePath!)
            }
        }
        else{
            /// set the count of animals in section 2
            cell.textLabel?.text = "\(filteredAnimalList.count) Animals"
        }
        return cell
    }
    
    /// This function is use dto detect any cell selection in the table view
    ///
    /// - Parameters:
    ///   - tableView: table view
    ///   - indexPath: row number selected in section
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        /// selected animal in the list
        let chosenAnimal: Animal?
        /// set the animal selected
        chosenAnimal = self.filteredAnimalList[indexPath.row]
        /// assign it to the delegate created in initial
        delegate?.animalSelected(chosenAnimal!)
        /// Calling focusOn method in Viewcontroller to handle the focus and select annotation
        self.viewController?.focusOn(animal: chosenAnimal!)
        
        //viewController?.definesPresentationContext = false
        /// to navigate to view controller i.e. map screen on selection of cell(Animal)
        if let viewController = delegate as? ViewController{
            splitViewController?.showDetailViewController(viewController, sender: nil)
        }
    }
    
    /// Method to handle delete cell from table on swipe in list
    ///
    /// - Parameters:
    ///   - tableView: table view
    ///   - editingStyle: delete/edit
    ///   - indexPath: selected cell index
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        /// if the selected action is delete
        if editingStyle == .delete {
            deleteAnimalIndexPath = indexPath
            let animalToDelete = filteredAnimalList[indexPath.row].name
            /// call method to handle confirmation to delete the cell selected to delete
            confirmDelete(animal: animalToDelete!)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    
    // MARK: - Search animal in list and related functions
    
    /// This Function handles the filtering on list based on entered text in search
    ///
    /// - Parameters:
    ///   - searchBar: search bar on top of list
    ///   - selectedScope: scope of search
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        
        filterContentForSearchText(selectedIndex: selectedScope)
    }
    
    /// This function handles the sorting of list based on the segmented control element selected
    /// Reference - Tutorial material ApporvMote
    /// - Parameter selectedIndex: the index of segment control
    func filterContentForSearchText(selectedIndex: Int){
        /// if it is the first index. sort it A-Z based on NAme attribute of Animal
        if selectedIndex == 0{
            filteredAnimalList.sort(by:{$0.name!.lowercased() < $1.name!.lowercased()})
            tableView.reloadData()
        }
        /// if it is the second index. sort it Z-A based on NAme attribute of Animal
        if selectedIndex == 1{
            filteredAnimalList.sort(by:{$0.name!.lowercased() > $1.name!.lowercased()})
            tableView.reloadData()
        }
    }
    
    /// To update the results on the list when user enters text in search bar
    ///
    /// - Parameter searchController: desc
    func updateSearchResults(for searchController: UISearchController) {
       
        if let searchText = searchController.searchBar.text, searchText.count > 0 {
            filteredAnimalList = animalList.filter({(animal:Animal) -> Bool in
                return (animal.name?.contains(searchText))!
            })
        }
        else {
            filteredAnimalList = animalList;
            
        }
        tableView.reloadData();
    }
    
    /// function to save the data in core data
    func saveData() {
        do {
            try managedObjectContext.save()
            
        }
        catch let error {
            print("Could not save Core Data: \(error)")
        } }

    // MARK: - Fetching image from core data
    
    /// This function helps to fetch the image from the core data based on the path provided
    ///
    /// - Parameter fileName: image path in core data
    /// - Returns: image matching the path in core data
    func loadImageData(fileName: String) -> UIImage? {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                       .userDomainMask, true)[0] as String
        let url = NSURL(fileURLWithPath: path)
        var image: UIImage?
        if let pathComponent = url.appendingPathComponent(fileName) {
            let filePath = pathComponent.path
            let fileManager = FileManager.default
            let fileData = fileManager.contents(atPath: filePath)
            image = UIImage(data: fileData!)
        }
        return image
    }
    
    // MARK :- functions related to deleting an item from the list
    
    /// Method to handle confirm delete featrue
    /// Reference - Youtube tutorial by Confidance labs
    /// - Parameter animal: selected animal
    func confirmDelete(animal:String){
        let alert = UIAlertController(title: "Delete Animal", message: "Are you sure you want to permanently delete \(animal)?", preferredStyle: .actionSheet)
        let DeleteAction = UIAlertAction(title: "Delete", style: .destructive, handler: handleDeleteAnimal)
        let CancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: cancelAnimalDeletion)
        
        alert.addAction(DeleteAction)
        alert.addAction(CancelAction)
        
        self.present(alert,animated: true,completion: nil)
    }
    
    /// Method to handle deleting the cell value from table and core data and refreshing the tableview
    ///
    /// - Parameter alertAction: desc
    func handleDeleteAnimal(alertAction:UIAlertAction!) -> Void{
        if let indexPath = deleteAnimalIndexPath {
            tableView.beginUpdates()
            /// delete the animal object from the core data
            managedObjectContext.delete(self.filteredAnimalList[indexPath.row])
            /// delete geofence for that animal as well
            removeGeoFencing(animal: self.filteredAnimalList[indexPath.row])
            
            do{
                try managedObjectContext.save()
                /// remove the entry from the list
                filteredAnimalList.remove(at: indexPath.row)
                /// reload the data from the core data for consistency
                let fetchRequest = NSFetchRequest<NSManagedObject>(entityName:"Animal")
                do{
                    animalList = try managedObjectContext.fetch(fetchRequest) as! [Animal]
                    animalList.sort(by:{$0.name! < $1.name!})
                }
                catch{
                    fatalError("Failed to fetch animals: \(error)")
                }
            }catch{
                print(error)
            }
            
            /// reload the sections in the table
            tableView.reloadSections([SECTION_COUNT], with: .automatic)
            tableView.deleteRows(at: [indexPath], with: .fade)
            tableView.endUpdates()
        }
    }
    
    /// Method to handle cancel option seelction in confirm delete
    ///
    /// - Parameter alertAction: alert pop up
    func cancelAnimalDeletion(alertAction:UIAlertAction!){
        deleteAnimalIndexPath = nil
    }
    
    /// Fucntion to handle deletion of geofence area and circle around it
    /// Written by self with debugging
    /// - Parameter animal: Animal seelcted to delete
    func removeGeoFencing(animal: Animal) {
        /// checking for each region if it matches with the region of animal to be deleted
        for region in (self.viewController?.locationManager.monitoredRegions)! {
            /// animal.name was set as identifer while setting the geofence for each animal. fetch that and check if it matches with any region
            guard let circularRegion = region as? CLCircularRegion, circularRegion.identifier == animal.name else { continue }
            /// if it mathches. just stop monitoring for the geofence
            self.viewController?.locationManager.stopMonitoring(for: circularRegion)
            
            /// Now to delete the circular region around the geofence area
            let circle = MKCircle(center: animal.coordinate, radius: 100)
            self.viewController?.mapView.remove(circle)
            /// to delete the overlay on maoview we need to check first the overlay we want i.e. of animal to be deleted. fetch all overlays
            let overlays = self.viewController?.mapView.overlays
            /// check for overlay with our coordinates and remove if found
            for overlay in overlays!{
                if (overlay.coordinate.latitude == animal.coordinate.latitude && overlay.coordinate.longitude == animal.coordinate.longitude){
                    self.viewController?.mapView.remove(overlay)
                }
            }
        }
    }
}


