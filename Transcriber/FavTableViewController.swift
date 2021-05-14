//
//  FavTableViewController.swift
//  Transcriber
//
//  Created by Sandeep Gautam on 10/05/2021.
//

import UIKit
import Foundation
import CoreData
import Speech

class FavTableViewController: UITableViewController {
    
    var favTranscriptions: [NSManagedObject]? = [NSManagedObject]()
    var reuseIdentifier = "favouritesTableViewCell"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let res = CoreDataHelper().getFavTranscriptions()
        print("Number of favourite coredata: \(res?.count)")
        
        
        checkForPermissions()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let res = CoreDataHelper().getFavTranscriptions() {
            favTranscriptions = res
        }
        
        tableView.reloadData()
    }
    
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return (favTranscriptions?.count)!
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        
        let transc = favTranscriptions?[indexPath.row]
        // Configure the cell...
        
        if let name = transc?.value(forKey: "audioFileName") {
            if name as! String == "" {
                cell.textLabel?.text = "Unnamed recording"
            } else {
                cell.textLabel?.text = "\(name)"
            }
        }
        else {
            cell.textLabel?.text = "\(String(describing: transc?.value(forKey: "audioFileURLString")))"
        }


        return cell
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "favSegueIdentifier", sender: indexPath.row)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let destination = segue.destination as? PlayViewController {
            let selectedRow = sender as? Int
            if let selectedObject = favTranscriptions?[selectedRow!] {
                destination.item = selectedObject
            }
        }
        
        
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            let appDel: AppDelegate = UIApplication.shared.delegate as! AppDelegate
            let context: NSManagedObjectContext = appDel.persistentContainer.viewContext
            
            let objectToDelete = favTranscriptions?[indexPath.row]
            
            let audioLink: String = favTranscriptions?[indexPath.row].value(forKey: "audioFileURLString") as! String
            let textLink: String = favTranscriptions?[indexPath.row].value(forKey: "textFileURLString") as! String
            
            let audioURL = URL(fileURLWithPath: audioLink)
            let textURL = URL(fileURLWithPath: textLink)
            
            let fm = FileManager.default
            
            do {
                try fm.removeItem(at: audioURL)
                try fm.removeItem(at: textURL )
                print("deleted!")
            } catch {
                print("cant delete")
            }
            
            favTranscriptions?.remove(at: indexPath.row)
            
            if let otd = objectToDelete {
                context.delete(otd)
            }
            
            appDel.saveContext()
            tableView.deleteRows(at: [indexPath], with: .fade)
            
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    
    func checkForPermissions() {
        let recAuthorized = AVAudioSession.sharedInstance().recordPermission == .granted
        let transAuthorized = SFSpeechRecognizer.authorizationStatus() == .authorized
        
        let authorized = recAuthorized && transAuthorized
        
        if !authorized {
            if let viewController = self.storyboard?.instantiateViewController(identifier: "PermissionsViewController") {
                self.navigationController?.present(viewController, animated: true, completion: nil)
            }
        }
    }
}
