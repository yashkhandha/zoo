//
//  AnimalTableViewCell.swift
//  Assignment1
//
//  Created by Yash Khandha on 2/9/18.
//  Copyright © 2018 Yash Khandha. All rights reserved.
//

/// Importing UIKit to handle event driven user interface
import UIKit

/// Class to manage the cell in the search animal on list screen
class AnimalTableViewCell: UITableViewCell {

    /// to display the animal name
    @IBOutlet weak var animalName: UILabel!
    /// to display the description of the animal
    @IBOutlet weak var animalDescription: UILabel!
    /// to display the image of the animal on the list
    @IBOutlet weak var animalImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    /// function to set the selected value on cell
    ///
    /// - Parameters:
    ///   - selected: selected cell
    ///   - animated: boolean value
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
