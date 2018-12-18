//
//  ArtworkViewController.swift
//  COMP327-Assignment-2
//
//  Created by Ben Hawley on 10/12/2018.
//  Copyright © 2018 Ben Hawley. All rights reserved.
//

import UIKit

class ArtworkViewController: UIViewController {

    
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    let imageDirectory = "https://cgi.csc.liv.ac.uk/~phil/Teaching/COMP327/artwork_images/"
    
    // Initialise empty artwork data
    var artwork = artworkData(id:"", title:"", artist:"", yearOfWork:"", Information:"", lat:"", long:"", location:"", locationNotes:"", fileName:"", lastModified:"", enabled:"")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "\(artwork.title)"

        artistNameLabel.text = artwork.artist
        titleLabel.text = artwork.title
        dateLabel.text = artwork.yearOfWork
        descriptionLabel.text = artwork.Information
        
        imageView.contentMode = .scaleAspectFit
        let encodedFileName = artwork.fileName.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? ""
        let imageLocation = imageDirectory + encodedFileName
        downloadImage(urlString: imageLocation)
        // Do any additional setup after loading the view.
    }

    func downloadImage(urlString: String) {
        if let url = URL(string: urlString) {
            print("Starting Download")
            // Session to coordinate network data transfer tasks
            let session = URLSession.shared
            
            // Attempts to retreive contents of specified URL
            session.dataTask(with: url) { (data, response, err) in
                
                guard let data = data else {return}
                
      
                // Get back to the main queue
                DispatchQueue.main.async {
                    print("Downloaded");
                    self.imageView.image = UIImage(data: data)
                }
                }.resume()
        }
        
    }

}
