//
//  ArtworkSelectorController.swift
//  COMP327-Assignment-2
//
//  Created by Ben Hawley on 17/12/2018.
//  Copyright © 2018 Ben Hawley. All rights reserved.
//

import UIKit

class ArtworkSelectorController: UITableViewController {
    
    var locationString = ""
    var artworks: [artworkData] = []
    var currentArtwork = -1

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = "Artwork at \(artworks[0].location)"


        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return artworks.count
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "myCell", for: indexPath)
        let row = indexPath.row
        cell.textLabel?.text = artworks[row].title
        cell.detailTextLabel?.text = artworks[row].artist
        // Configure the cell...
        return cell
    }
    
    // When we click a row, set the current year and report based on the index of the section and row
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        currentArtwork = indexPath.row
        
        // Segue to the report view controller
        performSegue(withIdentifier: "to Artwork From Selector", sender: tableView)
    }


    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // If we are going to view a report, send the reports data to the view
        if segue.identifier == "to Artwork From Selector" {
            let artWorkViewController = segue.destination as! ArtworkViewController
            let artwork: artworkData = artworks[currentArtwork]
            artWorkViewController.artwork = artwork;
        }
    }

}
