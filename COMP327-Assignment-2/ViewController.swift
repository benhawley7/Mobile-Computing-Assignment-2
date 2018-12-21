//
//  ViewController.swift
//  COMP327-Assignment-2
//
//  Created by Ben Hawley on 22/11/2018.
//  Copyright © 2018 Ben Hawley. All rights reserved.
//

// Import Modules
import UIKit
import MapKit
import CoreLocation
import CoreData

// Structure of the Artwork Model
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

// Structure of the Artworks2 JSON Data
struct artworksData: Decodable {
    let artworks2: [artworkData]
}

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MKMapViewDelegate, UISearchBarDelegate, CLLocationManagerDelegate {
    
    // Interface Element Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var artworkTable: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    // Global References to the App Delegate and NS Managed Object Context
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var context: NSManagedObjectContext?
    
    // Location Manager
    var locationManager:CLLocationManager!
    
    // Standard URL of the Artwork Endpoint
    let artworkURLString = "https://cgi.csc.liv.ac.uk/~phil/Teaching/COMP327/artworksOnCampus/data.php?class=artworks2"

    // Artworks in the session we have gathered from the cache
    var cachedArtworks: [artworkData] = []
    
    // Artworks in the session we gathered from the web
    var downloadedArtworks: [artworkData] = []
    
    // All the locations found across the artworks
    var locations: [String] = []
    
    // Never filtered artworks by location
    var unfilteredArtworksByLocation: Dictionary<String, [artworkData]> = [:]
    
    // Dictionary storing artworks keyed by their location
    var artworksByLocation: Dictionary<String, [artworkData]> = [:]
    
    // Dictionary to store attributed titles for indicating search results
    var attributedTitlesByID: Dictionary<String, NSMutableAttributedString> = [:]
    
    // Current location and artwork to send artwork to be viewed in another view
    var currentLocation = ""
    var currentArtwork = -1

    // Called when the view loads
    override func viewDidLoad() {
        // Super function!
        super.viewDidLoad()
        
        // Assign the context for core data
        context = appDelegate.persistentContainer.viewContext
        
        // Get artwork from the cache
        getArtworkFromCache()
        
        // Group the current cached artwork
        groupArtworksByLocation()
        
        // Get the last time we updated our data from UserStandards
        let lastUpdate = UserDefaults.standard.string(forKey: "lastUpdated") ?? nil
        
        // We have never updated before
        if lastUpdate == nil {
            downloadArtwork(urlString: artworkURLString)
        } else {
            // SYNCHRONISE :)
            // Download all of the data added after the last update
            downloadArtwork(urlString: "\(artworkURLString)&lastUpdate=\(lastUpdate ?? "")")
        }

        // Determine our current location, set the locations of artwork and reload the table
        determineCurrentLocation()
        setMapLocations()
        artworkTable.reloadData()
    }

    
    //
    // Functions for downloading, caching, and grouping artwork
    //
    
    // Gets the cached artwork from core data
    func getArtworkFromCache() {
        // Create a Fetch Request for the cached artwork
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Artwork")
        request.returnsObjectsAsFaults = false
        
        // Array to store the cached artworks
        var artworks: [artworkData] = []
        do {
            // Try Fetching the Core Data Artwork
            let results = try context?.fetch(request)
            
            // For each artwork record, append it to artwork array
            for result in results as! [NSManagedObject] {
                let id: String = result.value(forKey: "id") as! String
                let title: String = result.value(forKey: "title") as! String
                let artist: String = result.value(forKey: "artist") as! String
                let yearOfWork: String = result.value(forKey: "yearOfWork") as! String
                let Information: String = result.value(forKey: "Information") as! String
                let long: String = result.value(forKey: "long") as! String
                let lat: String = result.value(forKey: "lat") as! String
                let location: String = result.value(forKey: "location") as! String
                let locationNotes: String = result.value(forKey: "locationNotes") as! String
                let fileName: String = result.value(forKey: "fileName") as! String
                let lastModified: String = result.value(forKey: "lastModified") as! String
                let enabled: String = result.value(forKey: "enabled") as! String
                
                let artwork = artworkData(id:id, title:title, artist:artist, yearOfWork: yearOfWork, Information:Information, lat:lat, long:long, location:location, locationNotes:locationNotes, fileName:fileName, lastModified:lastModified, enabled:enabled)
                artworks.append(artwork)
            }
        } catch {
            print("Fetching CoreData Artworks Failed.")
        }
        // Assign the global cached artworks
        cachedArtworks = artworks;
    }
    
    // Gets the Artwork JSON from the weblink
    func downloadArtwork(urlString: String) {
        // Is the string a valid URL?
        if let url = URL(string: urlString) {
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
                    
                    var artworks: [artworkData] = []
                    for artwork in artworksList.artworks2 {
                        artworks.append(artwork)
                    }
                    
                    // Get back to the main queue
                    DispatchQueue.main.async {
                        let date = Date()
                        let formatter = DateFormatter()
                        
                        formatter.dateFormat = "yyyy-MM-dd"
                        let dateString = formatter.string(from: date)
            
                        // Set the variables
                        UserDefaults.standard.set(dateString, forKey: "lastUpdated")
        
                        self.downloadedArtworks = artworks
                        self.groupArtworksByLocation()
                        self.cacheDownloadedArtwork()
                        self.setMapLocations()
                        self.determineCurrentLocation()
                        self.artworkTable.reloadData()
                        self.unfilteredArtworksByLocation = self.artworksByLocation

                    }
                } catch let jsonErr {
                    print("Error decoding JSON.", jsonErr)
                    
                }
                }.resume()
        }
    }
    
    // Cache artwork we have downloaded in this session
    func cacheDownloadedArtwork() {
        for artwork in downloadedArtworks {
            // Create a Fetch Request for the cached artworks
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Artwork")
            request.returnsObjectsAsFaults = false
            
            do {
                // Try Fetching the Core Data Artworks
                let results = try context?.fetch(request)
                
                // For each result, determine if it needs deleting
                for result in results as! [NSManagedObject] {
                    let id: String = result.value(forKey: "id") as! String
                    // If we have this record ID already, we are going to be updating.
                    // So we need to delete this result
                    if id == artwork.id {
                        context?.delete(result)
                    }
                    
                }
            } catch {
                print("Error with comparison")
            }
            
            // Create a new core data object for the new/updated artwork
            let newArtwork = NSEntityDescription.insertNewObject(forEntityName: "Artwork", into: context!) as! Artwork
            newArtwork.id = artwork.id
            newArtwork.title = artwork.title
            newArtwork.artist = artwork.artist
            newArtwork.yearOfWork = artwork.yearOfWork
            newArtwork.information = artwork.Information
            newArtwork.lat = artwork.lat
            newArtwork.long = artwork.long
            newArtwork.location = artwork.location
            newArtwork.locationNotes = artwork.locationNotes
            newArtwork.fileName = artwork.fileName
            newArtwork.lastModified = artwork.lastModified
            newArtwork.enabled = artwork.enabled
        }
        
        // Save the coredata context
        do {
            try context?.save()
        } catch {
            print("Error saving CoreData changes")
        }
    }
    
    // Group the artworks into a dictionary keyed and grouped by location
    func groupArtworksByLocation() {
        // Array to store the available location strings across all the artworks
        locations = []
        
        // Get all the artworks
        let artworks = cachedArtworks + downloadedArtworks
        
        // For all the retreived artworks
        for artwork in artworks {
            // Check if the location has been added to the locationsx array and dictionary
            // If it hasn't been, add it
            let locationAdded = locations.contains { $0 == artwork.location }
            if locationAdded == false {
                locations.append(artwork.location)
                artworksByLocation[artwork.location] = []
            }
            
            // Append the artwork to the relevant dictionary array
            artworksByLocation[artwork.location]?.append(artwork)
        }
    }
    
    //
    // Search Bar Functions
    //

    // When the search bar button is clicked, closed it
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar)
    {
        self.searchBar.endEditing(true)
    }
    
    // This method updates filteredData based on the text in the Search Box
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // When we search, we need to make sure that we have access to all
        // of the artworks and that they are sorted by location
        groupArtworksByLocation()
        determineCurrentLocation()
        
        // If we have no search text, we need to remove all of the left over
        // Attributed titles from the previous search and reload the table
        if (searchText == "") {
            attributedTitlesByID.removeAll()
            artworkTable.reloadData()
            return
        }

        // For each location
        for location in locations {
            // Filter the artwork at that location by whether the title contains the search text
            artworksByLocation[location] = artworksByLocation[location]?.filter{
                // Get the title of the artwork
                let title = $0.title;
                
                // Create an attributed title
                let attributedTitle = NSMutableAttributedString(string: title)
                
                // Variable to indicate if we have a match
                var hasMatch: Bool = false
                do {
                    // Create a Regular expression using the search text
                    let regex = try NSRegularExpression(pattern: searchText, options: .caseInsensitive)
                    // Create a range of the title text
                    let range = NSRange(location: 0, length: title.utf16.count)
                    // For every match in the title
                    for match in regex.matches(in: title, options: .withTransparentBounds, range: range) {
                        // Update the attributed title with colour formatting in the match range text
                        let attributes: [NSAttributedString.Key: Any] = [
                            .backgroundColor : UIColor.yellow,
                            .font : UIFont.systemFont(ofSize: 16, weight: UIFont.Weight.bold)
                        ]
                        attributedTitle.addAttributes(attributes, range: match.range)
                        
                        // If we get here, we must have a match
                        hasMatch = true
                    }
                } catch _ {
                    print("Regex Failed - presume no match")
                    return false
                }
                
                // Set the attributed title to be accessed by the table cells later
                attributedTitlesByID[$0.id] = attributedTitle
                
                return hasMatch
            };
            
            // If a location no longer has artwork after filtering, we can remove it
            if (artworksByLocation[location]!.count == 0) {
                let locationIndex = locations.firstIndex(of: location)!
                locations.remove(at: locationIndex)
            }
        }
        artworkTable.reloadData()
    }
    
    
    //
    // Functions for determining the users location
    //
    
    // Determine the users current location
    func determineCurrentLocation()
    {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()

        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
        }
    }
    
    // Function for sorting the users location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation:CLLocation = locations[0] as CLLocation
        
        // Call stopUpdatingLocation() to stop listening for location updates,
        // other wise this function will be called every time when user location changes.
        //manager.stopUpdatingLocation()
        
        let center = CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.0025, longitudeDelta: 0.0025))
        
        mapView.setRegion(region, animated: true)

        // Now we know the users location, we can sort the artwork with it
        self.locations.sort{(a, b) -> Bool in
            // Get location of first artwork
            let artworkA = artworksByLocation[a]?[0]
            let latA = artworkA?.lat ?? ""
            let longA = artworkA?.long ?? ""
            guard let latitudeA = Double(latA) else { return false }
            guard let longitudeA = Double(longA) else { return false}
            let locationA = CLLocation(latitude: latitudeA, longitude: longitudeA)
            
            // Get location of second artwork
            let artworkB = artworksByLocation[b]?[0]
            let latB = artworkB?.lat ?? ""
            let longB = artworkB?.long ?? ""
            guard let latitudeB = Double(latB) else { return false}
            guard let longitudeB = Double(longB) else { return false }
            let locationB = CLLocation(latitude: latitudeB, longitude: longitudeB)
            
            // Work out the distance of the artworks from the users location
            let distanceA = locationA.distance(from: userLocation)
            let distanceB = locationB.distance(from: userLocation)
            
            // Return if the first is closer than the second
            return distanceA < distanceB
        }

        artworkTable.reloadData();

    }
    
    //
    // Functions for updating and interacting with the Map
    //
    
    // Set the locations of artwork on the map view
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
            
            // Create a coordinate with the lat and long values
            guard let latitude = Double(lat) else { return }
            guard let longitude = Double(long) else { return }
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)

            // Create an annotation with the cooridinate and the title of the location
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = artwork?.location
            
            // Add the annotation to the map
            mapView.addAnnotation(annotation)
            
        }
    }
    
    // Handles the click of an annotation on the map
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView)
    {
        // The annotation which has been clcked
        let annotation = view.annotation ?? nil;

        // Incase the annotation is nil
        guard annotation != nil else {
            return
        }
        
        // Set the current location to be the title of the annotation
        let annotationTitle = annotation?.title!
        currentLocation = annotationTitle ?? ""
        
        // If we have more than artwork at the location, go to the selector
        if (unfilteredArtworksByLocation[currentLocation]?.count ?? 0 > 1) {
            performSegue(withIdentifier: "to Artwork Selector", sender: mapView)
        } else {
            // Otherwise got to the artwork view
            currentArtwork = 0
            performSegue(withIdentifier: "to Artwork", sender: mapView)
        }
    }

    //
    // Functions for updating and interacting with the table
    //
    
    // The number of sections in the table is determiend by the Number of different unique artwork locations
    func numberOfSections(in tableView: UITableView) -> Int {
        return locations.count;
    }
    
    // The title of the section is the corresponding location of artworks sharing the the section index
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return locations[section]
    }
    
    // The number of rows in a section is determined by the number of artworks associated with its location section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return artworksByLocation[locations[section]]?.count ?? 0
    }
    
    // Give each cell its content
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "myCell", for: indexPath)
        let location = locations[indexPath.section]
        let artwork = artworksByLocation[location]?[indexPath.row]
        
        cell.detailTextLabel?.text = artwork?.artist;
        // If we don't have an attributed title, use the standard string
        guard let attributedTitle = attributedTitlesByID[artwork?.id ?? ""] else {
            cell.textLabel?.text = artwork?.title;
            return cell
        }
        
        // Attributed title for visual filtering
        cell.textLabel?.attributedText = attributedTitle
        return cell
    }
    
    // When we click a row, set current location and artwork based on the index of the section and row
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        currentLocation = locations[indexPath.section]
        currentArtwork = indexPath.row

        // Segue to the artwork view controller
        performSegue(withIdentifier: "to Artwork", sender: tableView)
    }
    
   
    // Called when about peform segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let senderType = "\(type(of: sender.unsafelyUnwrapped))"

        // If we are going to view an artwork, send the artwork data to the view
        if segue.identifier == "to Artwork" {
            // If we are coming from the map view, then we need to use the unfiltered results
            if senderType == "MKMapView" {
                // Set the artwork of the next view to be current selected location and artwork
                let artWorkViewController = segue.destination as! ArtworkViewController
                let artwork: artworkData = unfilteredArtworksByLocation[currentLocation]?[currentArtwork] ?? artWorkViewController.artwork;
                artWorkViewController.artwork = artwork;
                return
            }
            
            // Otherwise use the filtered results
            // Set the artwork of the next view to be current selected location and artwork
            let artWorkViewController = segue.destination as! ArtworkViewController
            let artwork: artworkData = artworksByLocation[currentLocation]?[currentArtwork] ?? artWorkViewController.artwork;
            artWorkViewController.artwork = artwork;
        }
        
        // If we are going to the artwork selector
        if segue.identifier == "to Artwork Selector" {
            // Set the artworks of the upcoming view to be those of the currently selected location
            let artworkSelectorController = segue.destination as! ArtworkSelectorController
            let artworks: [artworkData] = unfilteredArtworksByLocation[currentLocation] ?? []
            artworkSelectorController.artworks = artworks
        }
    }

}
