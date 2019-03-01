//
//  Animal+CoreDataClass.swift
//  Assignment1
//
//  Created by Yash Khandha on 2/9/18.
//  Copyright © 2018 Yash Khandha. All rights reserved.
//
//

/// Importing Foundation as basis of core data
import Foundation
/// Importing CoreData to handle data operations in core data
import CoreData
/// Importing MapKit to handle all access to its interfaces and functions
import MapKit

/// Animal class to manage the core data entity Animal
public class Animal: NSManagedObject {
}

extension Animal : MKAnnotation{
    
    /// to return the coordinates of animal
    public var coordinate: CLLocationCoordinate2D{
        
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    /// to return the title of annoptation as animal name
    public var title: String?{
        return name!
    }
    /// to return the subtitle of annotation as animal description
    public var subtitle: String?{
        return desc!
    }
    
    }
