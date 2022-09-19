//
//  ViewController.swift
//  Gmaps
//
//  Created by Pavankumar Arepu on 11/09/22.
//

import UIKit
import GooglePlaces


class StartedViewController: UIViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var placeTableView: UITableView!
    @IBOutlet private var nameLabel: UILabel!
    @IBOutlet private var addressLabel: UILabel!
    var resultObject: [Any] = []
    var nameArray: [String] = []
    var iconArray: [String] = []
    var iconBGColor: [String] = []
    
    var placeType = "cafe"
    var urlString = ""
    
    //"https://maps.googleapis.com/maps/api/place/nearbysearch/json?keyword=cruise&location=-33.8670522%2C151.1957362&radius=1500&type=cafe&key=\(ApiKeys.placesAPI)"
    /*
     https://maps.googleapis.com/maps/api/place/nearbysearch/json
     ?keyword=cruise
     &location=-33.8670522%2C151.1957362
     &radius=1500
     &type=restaurant
     &key=YOUR_API_KEY
     */
    
    let locationManager = CLLocationManager()
    var currentLocation: CLLocation!
    private var placesClient: GMSPlacesClient!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        placesClient = GMSPlacesClient.shared()
        
        // Do any additional setup after loading the view.
        locationManager.delegate = self
        
        if CLLocationManager.authorizationStatus() == .notDetermined
        {
            locationManager.requestWhenInUseAuthorization()
        }
        
        currentLocation = locationManager.location
        //print("Current Lat, Long", currentLocation.coordinate.latitude,currentLocation.coordinate.longitude)
        
        let x = currentLocation.coordinate.latitude
        let lat = Double(round(10000000 * x) / 10000000)
        print(lat) /// 1.236
        
        let y = currentLocation.coordinate.longitude
        let long = Double(round(10000000 * y) / 10000000)
        print(long) /// 1.236
        
        
        /// For 'keyword' https://developers.google.com/maps/documentation/places/ios-sdk/supported_types
        
        urlString = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?keyword=atm&location=-33.8670522%2C151.1957362&radius=1500&type=restaurant&key=\(ApiKeys.placesAPI)"
        //
        /*
         urlString = """
         https://maps.googleapis.com/maps/api/place/nearbysearch/json
         ?keyword=Broma
         &location=-33.8670522%2C151.1957362
         &radius=15000
         &type=cafe
         &key=<APIKEy>
         """
         
         let trimmedString = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
         
         urlString = trimmedString
         
         */
        print("URLString: ", urlString)
        
//        placeTableView.delegate = self
        placeTableView.dataSource = self
    }
    
    // Add a UIButton in Interface Builder, and connect the action to this function.
    @IBAction func getCurrentPlace(_ sender: UIButton) {
        
        webServiceHit(url: urlString)
        
        let placeFields: GMSPlaceField = [.name, .formattedAddress]
        
        placesClient.findPlaceLikelihoodsFromCurrentLocation(withPlaceFields: placeFields) { [weak self] (placeLikelihoods, error) in
            guard let strongSelf = self else {
                return
            }
            
            guard error == nil else {
                print("Current place error: \(error?.localizedDescription ?? "")")
                return
            }
            
            guard let place = placeLikelihoods?.first?.place else {
                strongSelf.nameLabel.text = "No current place"
                strongSelf.addressLabel.text = ""
                return
            }
            
            strongSelf.nameLabel.text = place.name
            strongSelf.addressLabel.text = place.formattedAddress
        }
    }
    
    func webServiceHit(url: String) {
        
        let url  = NSURL.init(string: url)
        guard let urlString = url else {
            return
        }
        let urlRequest = URLRequest.init(url: urlString as URL)
        let task = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            print("Data:", data as Any)
            let str = String(decoding: data!, as: UTF8.self)
            
            let dict = self.convertStringToDictionary(text: str)
            
            print("str data:", str as Any)
            print("Response:", response as Any)
            print("Error:", error as Any)
            
            self.resultObject = dict?["results"] as! [Any]
            print("ResultObject", self.resultObject )
            
            self.prepareData(result: self.resultObject as Array<Any>)
            DispatchQueue.main.async {
                print("Download Compelted")
                self.placeTableView.reloadData()
            }
        }
        task.resume()
        
    }
    
    func convertStringToDictionary(text: String) -> [String:AnyObject]? {
        if let data = text.data(using: .utf8) {
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String:AnyObject]
                return json
            } catch {
                print("Something went wrong")
            }
        }
        return nil
    }
    
    func prepareData(result: Array<Any>) {
        print("Result Objbect APK ", result)
        
        for dict in result {
            
            if let jsonResult = dict as? Dictionary<String, AnyObject> {
                // do whatever with jsonResult
                print("Dict", jsonResult)
                print("name", jsonResult["name"] ?? "")

                if let name = jsonResult["name"],
                   let image = jsonResult["icon"],
                   let imageBG = jsonResult["icon_background_color"] {
                    self.nameArray.append(name as! String)
                    self.iconArray.append(image as! String)
                    self.iconBGColor.append(imageBG as! String)
                }
            }
        }
        print("NameArray:", nameArray, nameArray.count)
        print("iconArray:", iconArray, iconArray.count)
        print("iconBG:", iconBGColor, iconBGColor.count)
    }
}


extension StartedViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        nameArray.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        86
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Creating a tableview cell
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! PlacesTableViewCell
        cell.placeLabel.text = "\(nameArray[indexPath.row])"
        
     
        
        let task = URLSession.shared.dataTask(with: URL(string: "\(iconArray[indexPath.row])")!, completionHandler: { data, response, error in
            // Do something with image data...
            if let receivedData = data {
                DispatchQueue.main.async {
                    cell.placeImage.image = UIImage.init(data: receivedData)
//                    cell.placeImage.backgroundColor = UIColor(named: "\(self.iconBGColor[indexPath.row])")
                }
                print("ReceivedData:", receivedData)
            }
        })
        
        task.resume()
        
        
        print("Data --> Cell Address --> indexpath", cell.textLabel?.text as Any, cell, indexPath)
        
        // returning a cell
        return cell
    }
}

