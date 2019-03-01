//
//  Animal+CoreDataProperties.swift
//  Assignment1
//
//  Created by Yash Khandha on 2/9/18.
//  Copyright © 2018 Yash Khandha. All rights reserved.
//
//

import Foundation
import CoreData
import MapKit

// MARK: - Extension to our entity Animal
extension Animal{

    /// function to fetch the attribute values of entity Animal
    ///
    /// - Returns: entity
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Animal> {
        return NSFetchRequest<Animal>(entityName: "Animal")
    }

    /// to save the description of animal
    @NSManaged public var desc: String?
    /// to store the longitude value of animal's location
    @NSManaged public var longitude: Double
    /// to store the latitude value of animal's location
    @NSManaged public var latitude: Double
    /// to store the image path of animals image
    @NSManaged public var imagePath: String?
    /// to store the sex of the animal
    @NSManaged public var sex: String?
    /// to store the breed of animals
    @NSManaged public var breed: String?
    /// to store the colour of animal
    @NSManaged public var color: String?
    /// to store the food intake of the animal
    @NSManaged public var food: String?
    /// to store the icon details of the animal
    @NSManaged public var iconPath: String?
    /// to store the name of the animal
    @NSManaged public var name: String?

}


