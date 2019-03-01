//
//  AddAnimalViewController.swift
//  Assignment1
//
//  Created by Yash Khandha on 24/8/18.
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

/// To manage the map view once the animal is added in core data
protocol UpdateMapViewProtocol {
    func updateView(newAnimal:Animal)
}

/// Class to handle the new adition of animal
/// reference for UIPicker - https://codewithchris.com
class AddAnimalViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    /// name field on screen
    @IBOutlet weak var nameTextView: UITextField!
    /// description field
    @IBOutlet weak var descrTextView: UITextField!
    /// animal breed details
    @IBOutlet weak var breedTextView: UITextField!
    /// animal gender
    @IBOutlet weak var sexTextview: UITextField!
    /// animal color
    @IBOutlet weak var colorTextView: UITextField!
    /// animal diet
    @IBOutlet weak var dietTextView: UITextField!
    /// to save the image on screen
    @IBOutlet weak var imageView: UIImageView!
    /// to save the animal icon on screen
    @IBOutlet weak var iconView: UIImageView!
    /// to handle the alert controls
    var status :Bool = false
    /// delegate to handle the updation of entity after saving the animal
    var newAnimalDelegate:UpdateMapViewProtocol?
    /// to handle the list for breed
    private var listPicker: UIPickerView?
    /// to save the list of available animal breed
    var breedList: [String] = [String]()
    
    /// Core data
    var appDelegate: AppDelegate?
    var managedObjectContext: NSManagedObjectContext?
    var newAnimalAnnotation: MKAnnotation?
    
    /// Method on itial load
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// to create link to coredata
        appDelegate = UIApplication.shared.delegate as? AppDelegate
        managedObjectContext = (appDelegate?.persistentContainer.viewContext)
        
        /// list of breed for animals to display in list
        breedList = ["","Kangaroo","Rabbit","Koala","Bear","Gorilla","Monkey","Other"]
        /// initialise UIPickerView for list
        listPicker = UIPickerView()
        listPicker?.showsSelectionIndicator = true
        self.listPicker?.delegate = self
        self.listPicker?.dataSource = self
        
        /// initialise toolbar and set the attributes
        let toolbar = UIToolbar()
        toolbar.barStyle = UIBarStyle.default
        toolbar.isTranslucent = true
        toolbar.sizeToFit()
        
        /// Buttons to show on picker view
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(donePicker))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(donePicker))
        
        /// set these butotns on the toolbar
        toolbar.setItems([cancelButton,spaceButton,doneButton], animated: true)
        toolbar.isUserInteractionEnabled = true
        /// set the value selected in breed text view
        breedTextView.inputView = listPicker
        breedTextView.inputAccessoryView = toolbar
    }
    
    /// handle click of done button
    @objc func donePicker(){
        breedTextView.resignFirstResponder()
    }
    
    /// to handle memory issues
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /// Funciton to handle adding image using camera or gallery
    ///
    /// - Parameter sender: any
    @IBAction func addImageButton(_ sender: Any) {
        /// initialise UIImagePickerController instance
        let controller = UIImagePickerController()
        /// if camera source is available then open camera for taking pictures
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera)
        {
            controller.sourceType = UIImagePickerControllerSourceType.camera
        }
            /// or else pick form gallery
        else
        {
            controller.sourceType = UIImagePickerControllerSourceType.photoLibrary
        }
        /// option to crop the image
        controller.allowsEditing = true
        controller.delegate = self
        self.present(controller, animated: true, completion: nil)
    }
    
    /// Method to pik image from gallery
    ///
    /// - Parameters:
    ///   - picker: picker
    ///   - info: none
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage]
            as? UIImage {
            imageView.image = pickedImage
        }
        dismiss(animated: true, completion: nil)
    }
    
    /// Function to handle cancel button
    ///
    /// - Parameter picker: picker
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        displayMessage("There was an error in getting the photo", "Error")
        self.dismiss(animated: true, completion: nil)
    }
    
    /// Function called to display alert messages
    ///
    /// - Parameters:
    ///   - message:
    ///   - title: title of the alert
    func displayMessage(_ message: String,_ title: String) {
        let alertController = UIAlertController(title: title, message: message,
                                                preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title:"Dismiss",style:UIAlertActionStyle.default,handler: {(action) in
            if self.status{
                self.navigationController?.popViewController(animated: true)
            }
        }))
        self.present(alertController, animated: true, completion: nil)
    }
    
    /// Function to save the animal in the core data
    ///
    /// - Parameter sender: any
    @IBAction func saveAnimalButton(_ sender: Any) {
        
        /// Validation to check if all fields are not empty and process it further or else go to else section
        if (validate(textView: nameTextView) && validate(textView: descrTextView) && validate(textView: breedTextView) && validate(textView: sexTextview) && validate(textView: colorTextView)
            && validate(textView: dietTextView)){
            
            if (nameTextView.text?.count)! < 4 {
                displayMessage("Animal name should be atleats 4 characters long", "Oops! Something went wrong")
                return
            }
            
            /// if image is not picked, give alert message
            guard let image = imageView.image else {
                displayMessage("Please select a picture to save animal", "Oops! Something went wrong")
                return
            }
            /// if the image is still the default one, ask for image
            if image == UIImage(named: "camera-2"){
                displayMessage("Please select a picture to save animal", "Oops! Something went wrong")
                return
            }
            
            /// If everything is a success, then first create image path for the image selected to be stored in the core data
            let date = UInt(Date().timeIntervalSince1970)
            var data = Data()
            data = UIImageJPEGRepresentation(image, 0.8)!
            let path = NSSearchPathForDirectoriesInDomains(.documentDirectory,.userDomainMask, true)[0] as String
            let url = NSURL(fileURLWithPath: path)
            if let pathComponent = url.appendingPathComponent("\(date)") {
                let filePath = pathComponent.path
                let fileManager = FileManager.default
                fileManager.createFile(atPath: filePath, contents: data, attributes:
                    nil)
                /// set all the values in Animal instance to save in core data
                let newAnimal = NSEntityDescription.insertNewObject(forEntityName:
                    "Animal", into: managedObjectContext!) as! Animal
                newAnimal.name = nameTextView.text!
                newAnimal.desc = descrTextView.text!
                newAnimal.breed = breedTextView.text!
                newAnimal.sex = sexTextview.text!
                newAnimal.color = colorTextView.text!
                newAnimal.food = dietTextView.text!
                newAnimal.iconPath = "\(date)"
                newAnimal.latitude = (newAnimalAnnotation?.coordinate.latitude)!
                newAnimal.longitude = (newAnimalAnnotation?.coordinate.longitude)!
                newAnimal.imagePath = "\(date)"
                do {
                    try self.managedObjectContext?.save()
                    /// telling map view to run this method to update view
                    self.newAnimalDelegate?.updateView(newAnimal: newAnimal)
                    displayMessage("\(nameTextView.text!) added to the Monash Zoo. ", "Wohoo!")
                    status = true
                } catch {
                    displayMessage("Could not save to database", "Error")
                }
            }
        }
            /// if fields are not filled with data
        else{
            let alertController = UIAlertController(title: "Oops! Something went wrong", message: "Please enter all the fields to add animal",
                                                    preferredStyle: UIAlertControllerStyle.alert)
            alertController.addAction(UIAlertAction(title:"Ok",style:UIAlertActionStyle.default,handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }    
    }
    
    /// function to check if any textfield is blank
    ///
    /// - Parameter textView: text view
    /// - Returns: boolean
    func validate(textView: UITextField) -> Bool {
        guard let text = textView.text,
            !text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty else {
                // this will be reached
                // if the text only contains white spaces
                // or no text at all
                return false
        }
        return true
    }
    
    /// Picker view method to define the number of components in view
    ///
    /// - Parameter pickerView: view
    /// - Returns: int
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    /// Picker view method to check number of items in list
    ///
    /// - Parameters:
    ///   - pickerView: view
    ///   - component: number of components
    /// - Returns: number of items in list
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return breedList.count
    }
    
    /// Picker view function to handle the display of items with title
    ///
    /// - Parameters:
    ///   - pickerView: view
    ///   - row: row selected
    ///   - component: integer
    /// - Returns: title value
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return breedList[row]
    }
    
    /// Picker view method to set icon image based on breed selected in the list from assets
    ///
    /// - Parameters:
    ///   - pickerView: vier
    ///   - row: entry
    ///   - component: integer
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        breedTextView.text = breedList[row]
        if (breedList[row] == "Kangaroo"){
            iconView.image = UIImage(named: "kangaroo-1")
        }
        else if (breedList[row] == "Rabbit"){
            iconView.image = UIImage(named: "rabbit-icon-1")
        }
        else if (breedList[row] == "Koala"){
            iconView.image = UIImage(named: "koala-icon-2")
        }
        else if (breedList[row] == "Bear"){
            iconView.image = UIImage(named: "bear-icon-1")
        }
        else if (breedList[row] == "Gorilla"){
            iconView.image = UIImage(named: "gorilla-icon-1")
        }
        else if (breedList[row] == "Monkey"){
            iconView.image = UIImage(named: "monkey-icon-1")
        }
        else if (breedList[row] == ""){
            iconView.image = UIImage(named: "default-icon")
        }
        else if (breedList[row] == "Other"){
            iconView.image = UIImage(named: "other-1")
        }
    }
}
