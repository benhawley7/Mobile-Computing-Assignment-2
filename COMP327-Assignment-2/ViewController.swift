//
//  ViewController.swift
//  COMP327-Assignment-2
//
//  Created by Ben Hawley on 22/11/2018.
//  Copyright © 2018 Ben Hawley. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation


class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, CLLocationManagerDelegate {

    

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var artworkTable: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    var locationManager:CLLocationManager!

    
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        print("Do we even gret here?")
//        return 10;
//    }
//
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = UITableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: "myCell")
//        cell.textLabel?.text = "WHy isnt this worlign"
//        return cell
//    }
    
    
    let artworkURLString = "https://cgi.csc.liv.ac.uk/~phil/Teaching/COMP327/artworksOnCampus/data.php?class=artworks2&lastUpdate=2017-11-01"
    
    // Structure of the Tech Report Model
    struct artworkData: Decodable {
        let id: String
        let title: String
        let artist: String
        let yearOfWork: String
        let Information: String
        let lat: String
        let long: String
        let location: String
        let locationNotes: String
        let fileName: String
        let lastModified: String
        let enabled: String
    }
    
    // Structure of the Technical Reports JSON Data
    struct artworksData: Decodable {
        let artworks2: [artworkData]
    }
    var artworksByLocation: Dictionary<String, [artworkData]> = [:]
    var locations: [String] = []
    var currentLocation = ""
    var currentArtwork = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getArtworkJSON()

        artworkTable.reloadData()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    // Gets the Reports JSON from the weblink and sorts them to be keyed by Year
    func getArtworkJSON() {
        // Is the string a valid URL?
        if let url = URL(string: artworkURLString) {
            // Session to coordinate network data transfer tasks
            let session = URLSession.shared
            
            // Attempts to retreive contents of specified URL
            session.dataTask(with: url) { (data, response, err) in
                
                // Assign the data to jsonData or return
                guard let jsonData = data else {return}
                
                do {
                    // Attempt to decode JSON with our provided structures
                    let decoder = JSONDecoder()
                    let artworksList = try decoder.decode(artworksData.self, from: jsonData)
                    
                    
//                    print(artworksList)
                    // Dictionary store arrays of reports, keyed by Year
                    var artworksByLocation: Dictionary<String, [artworkData]> = [:]
                    
//
                    // Array to store the available location strings across all the artworks
                    var locations: [String] = []
//
                    // For all the retreived reports
                    for artwork in artworksList.artworks2 {
                        // Check if the year has been added to the years array and dictionary
                        // If it hasn't been, add it
                        let locationAdded = locations.contains { $0 == artwork.location }
                        if locationAdded == false {
                            locations.append(artwork.location)
                            artworksByLocation[artwork.location] = []
                        }

                        // Append the report to the relevant dictionary array
                        artworksByLocation[artwork.location]?.append(artwork)
                    }
//
//                    // Sort the years - this is so the sections can iterate over the years in order
                    locations = locations.sorted(by: { $0 < $1 })
                    
                    // Get back to the main queue
                    DispatchQueue.main.async {
                        // Set the variables
                        self.locations = locations
                        self.artworksByLocation = artworksByLocation
                        // Reload the table
                        self.artworkTable.reloadData()
                        self.setMapLocations();
                        self.determineCurrentLocation()
//                        self.activityIndicator.stopAnimating()
//
                    }
                } catch let jsonErr {
                    print("Error decoding JSON.", jsonErr)
                    
                }
                }.resume()
        }
    }
    

    func determineCurrentLocation()
    {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()

        if CLLocationManager.locationServicesEnabled() {
            //locationManager.startUpdatingHeading()
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation:CLLocation = locations[0] as CLLocation
        
        // Call stopUpdatingLocation() to stop listening for location updates,
        // other wise this function will be called every time when user location changes.
        //manager.stopUpdatingLocation()
        
        let center = CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        
        mapView.setRegion(region, animated: true)
    }
    
    func setMapLocations() {
        for location in locations {
            // Get one of the artwork locations lat and long to be used
            let artwork = artworksByLocation[location]?[0]
            
            guard let long = artwork?.long else {
                return
            }
            guard let lat = artwork?.lat else {
                return
            }
            
            guard let latitude = Double(lat) else { return }
            guard let longitude = Double(long) else { return }
//            let span = MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)


            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = artwork?.location
            
            mapView.addAnnotation(annotation)
            
  
        }
    }

    
    // The number of sections in the table is determiend by the Number of different unique Report Years
    func numberOfSections(in tableView: UITableView) -> Int {
        return locations.count;
    }
    
    // The title of the section is the corresponding Year sharing the the section index
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return locations[section]
    }
    
    // The number of rows in a section is determined by the number of reports associated with its year section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return artworksByLocation[locations[section]]?.count ?? 0
    }
    
    // Adjust each cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "myCell", for: indexPath)
        let location = locations[indexPath.section]
        cell.textLabel?.text = artworksByLocation[location]?[indexPath.row].title;
        return cell
    }
    
    // When we click a row, set the current year and report based on the index of the section and row
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        currentLocation = locations[indexPath.section]
        currentArtwork = indexPath.row

        // Segue to the report view controller
        self.performSegue(withIdentifier: "to Artwork", sender: self)
    }
    
    // Called when about peform segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // If we are going to view a report, send the reports data to the view
        if segue.identifier == "to Artwork" {
//            let viewController = segue.destination as! ViewController
//            let report: techReport = reportsByYear[currentYear]?[currentReport] ?? viewController.report
//            viewController.report = report;
        }
    }

}
