//
//  AnimalDetailViewController.swift
//  Assignment1
//
//  Created by Yash Khandha on 17/8/18.
//  Copyright © 2018 Yash Khandha. All rights reserved.
//

/// Importing UIKit to handle event driven user interface
import UIKit
/// Importing Mapkit to access map and its functions
import MapKit
/// Importing CoreData to access the entities and properties linked with it
import CoreData

/// Class to handle the display of selected animal details
class AnimalDetailViewController: UIViewController {

    /// to display animal name
    @IBOutlet weak var nameLabel: UILabel!
    /// to display animal description
    @IBOutlet weak var descriptionLabel: UILabel!
    /// to display animal breed
    @IBOutlet weak var breedLabel: UILabel!
    /// to display animal sex
    @IBOutlet weak var sexLabel: UILabel!
    /// to display animal color
    @IBOutlet weak var colorLabel: UILabel!
    /// to display animal food habbits
    @IBOutlet weak var dietLabel: UILabel!
    /// to display image of animal
    @IBOutlet weak var imageView: UIImageView!
    /// to display lcoation of animal
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    /// to save the animal passed form the map view
    var animalDetail : Animal?
    
    /// Initial load funciton
    override func viewDidLoad() {
        super.viewDidLoad()
        /// setting the value of animal object passed into the labels
        nameLabel.text = animalDetail?.name
        descriptionLabel.text = animalDetail?.desc
        breedLabel.text = animalDetail?.breed
        sexLabel.text = animalDetail?.sex
        colorLabel.text = animalDetail?.color
        dietLabel.text = animalDetail?.food
        
        /// To check is the path length for image is greater than particular value to differentiate to load image from assets(for default animals) or core data(newly added animals)
        if (animalDetail?.imagePath?.count)! > 9 {
            /// load image from core data
            imageView.image = loadImageData(fileName: (animalDetail?.imagePath!)!)
        }
        else{
            /// load the image from assets
            imageView.image = UIImage(named: (animalDetail?.imagePath)!)
        }
        
        /// to handle the double values ot be stored in the string and then to labels
        let latitudeValue = animalDetail?.latitude
        if let unwrappedLatitude = latitudeValue {
            let stringLatitude = "\(unwrappedLatitude)"
            latitudeLabel.text = stringLatitude
        }
        let longitudeValue = animalDetail?.longitude
        if let unwrappedLongitude = longitudeValue {
            let stringLongitude = "\(unwrappedLongitude)"
            longitudeLabel.text = stringLongitude
        }
    }
    
    /// to handle memory warning
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
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
}
