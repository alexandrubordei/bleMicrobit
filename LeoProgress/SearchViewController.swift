//
//  SearchViewController.swift
//  BLEtest
//
//  Created by Alexandru Bordei on 9/2/19.
//  Copyright © 2019 Alexandru Bordei. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class SearchViewController:UIViewController, MKLocalSearchCompleterDelegate, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource{
    
    

    var region:MKCoordinateRegion? = nil
    
    let completer = MKLocalSearchCompleter()
    var searchResults = [MKLocalSearchCompletion]()
    
    var localSearch: MKLocalSearch?
    var boundingRegion:MKCoordinateRegion?
    var places = [MKMapItem]()
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        completer.delegate = self
        completer.region = region!
        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        
    }
    
    func searchBar(_ searchBar: UISearchBar,
                   textDidChange searchText: String)
    {
        completer.queryFragment = searchText
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter)
    {
        searchResults = completer.results
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "tableViewCell")//UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        
        
        
        let searchResult = searchResults[indexPath.row]
        
        cell?.textLabel?.text = searchResult.title
        cell?.detailTextLabel?.text = searchResult.subtitle
        
        return cell!
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
       
        
       // self.performSegue(withIdentifier: "showSearch", sender: self)
    }
    
    
    private func searchForLocation(using searchRequest: MKLocalSearch.Request) {
        // Confine the map search area to an area around the user's current location.
        
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
    
        if segue.destination is MainViewController
        {
            let mainVC = segue.destination as! MainViewController
            if(self.tableView.indexPathForSelectedRow != nil)
            {
                let selectedIndex = self.tableView.indexPathForSelectedRow?.row
                
                let selectedCompletion = searchResults[selectedIndex!]
                
                mainVC.destinationCompletion = selectedCompletion
            }
        }

        
    }
    
    
   
    
    func displaySearchError(error:Error)
    {
        //TODO
    }
}

