//
//  ArtworkViewController.swift
//  COMP327-Assignment-2
//
//  Created by Ben Hawley on 10/12/2018.
//  Copyright © 2018 Ben Hawley. All rights reserved.
//

import UIKit
class ArtworkViewController: UIViewController {

    // Outlets to the interface elements
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var locationNotesLabel: UILabel!
    
    // End point for the image directory
    let imageDirectory = "https://cgi.csc.liv.ac.uk/~phil/Teaching/COMP327/artwork_images/"

    // Initialise empty artwork data
    var artwork = artworkData(id:"", title:"", artist:"", yearOfWork:"", Information:"", lat:"", long:"", location:"", locationNotes:"", fileName:"", lastModified:"", enabled:"")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the page title
        self.navigationItem.title = "\(artwork.title)"

        // Set the content of the artwork view
        artistNameLabel.text = artwork.artist
        titleLabel.text = artwork.title
        dateLabel.text = artwork.yearOfWork
        descriptionLabel.text = artwork.Information
        locationLabel.text = "Location: \(artwork.location)"
        locationNotesLabel.text = "Notes: \(artwork.locationNotes)"
        
        // Set the image view to scale
        imageView.contentMode = .scaleAspectFit
        
        // Download the image - (we check if its cached in the downloadImage function)
        let encodedFileName = artwork.fileName.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
        let imageLocation = imageDirectory + encodedFileName
        downloadImage(urlString: imageLocation)

    }

    func downloadImage(urlString: String) {
        // Is the URL valid?
        if let url = URL(string: urlString) {
            // The image could be cached, lets create a file path and check if it exists
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let filePath = documentsURL.appendingPathComponent(artwork.fileName).path
            // If the file exists
            if FileManager.default.fileExists(atPath: filePath) {
                // Use the file data to form a UIImage and set the imageView to be the cached image
                let cachedImage = UIImage(contentsOfFile: filePath)
                imageView.image = cachedImage
                
                // Nothing more to do, return
                return
            }
            
            // If we get here, the image hasn't been cached
            // So we need to download it
            // Session to coordinate network data transfer tasks
            let session = URLSession.shared
            
            // Attempts to retreive contents of specified URL
            session.dataTask(with: url) { (data, response, err) in
                // The image data
                guard let data = data else {return}
      
                // Get back to the main queue
                DispatchQueue.main.async {
                    // Form an image using the data
                    let downloadedImage = UIImage(data: data)
                    
                    do {
                        // Try writing the image to file, using the filename found in the artwork
                        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                        let fileURL = documentsURL.appendingPathComponent("\(self.artwork.fileName)")
                        try data.write(to: fileURL, options: .atomic)
    
                    } catch {
                        print("Couldn't cache image.")
                    }
                    
                    // Set the image view to be the downloaded image
                    self.imageView.image = downloadedImage

                }
                }.resume()
        }
        
    }

}
