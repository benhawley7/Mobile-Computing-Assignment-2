//
//  ArtworkSelectorController.swift
//  COMP327-Assignment-2
//
//  Created by Ben Hawley on 17/12/2018.
//  Copyright © 2018 Ben Hawley. All rights reserved.
//

import UIKit

class ArtworkSelectorController: UITableViewController {
    
    // Location of the artworks
    var locationString = ""
    // Artworks at the location
    var artworks: [artworkData] = []
    // Current artwork
    var currentArtwork = -1

    override func viewDidLoad() {
        super.viewDidLoad()
        // Set the views title to be the current location of the artworks we are selecting
        self.navigationItem.title = "Artwork at \(artworks[0].location)"

    }
    
    // Determines number of sections in table
    override func numberOfSections(in tableView: UITableView) -> Int {
        // We will only ever have 1 location section
        return 1
    }

    // Determines number of rows in table
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Number of rows is equal to the number of artworks
        return artworks.count
    }

    // Assigns the content of cells in the table
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "myCell", for: indexPath)
        let row = indexPath.row
        
        // Use the index path to set the artwork content
        cell.textLabel?.text = artworks[row].title
        cell.detailTextLabel?.text = artworks[row].artist
        return cell
    }
    
    // When we click a row, set the current artworkx based on the index of the row
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        currentArtwork = indexPath.row

        // Segue to the report view controller
        performSegue(withIdentifier: "to Artwork From Selector", sender: tableView)
    }

    // Called before we segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // If we are going to view a report, send the reports data to the view
        if segue.identifier == "to Artwork From Selector" {
            // Assign the artwork property of the view we are about to segue to
            let artWorkViewController = segue.destination as! ArtworkViewController
            let artwork: artworkData = artworks[currentArtwork]
            artWorkViewController.artwork = artwork;
        }
    }

}
