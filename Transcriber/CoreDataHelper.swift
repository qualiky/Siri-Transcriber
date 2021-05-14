//
//  CoreDataHelper.swift
//  Transcriber
//
//  Created by Sandeep Gautam on 08/05/2021.
//

import Foundation
import CoreData
import UIKit

class CoreDataHelper {
    
    init () {
        let container = NSPersistentContainer(name: "Transcriber")
        container.loadPersistentStores { storeDescription, error in
            if let error = error {
                print("okchata: \(error.localizedDescription)")
            } else {
                print("okchata: core data available")
            }
        }
    }
    
    func getContext () -> NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }
    
    func storeTranscription(audioFileURLString: String, textFileURLString: String, audioFileName: String, isFav: Bool) {
        let context = getContext()
        
        let entity = NSEntityDescription.entity(forEntityName: "Transcription", in: context)
        let transcription = NSManagedObject(entity: entity!, insertInto: context)
        transcription.setValue(audioFileURLString, forKey: "audioFileURLString")
        transcription.setValue(textFileURLString, forKey: "textFileURLString")
        transcription.setValue(audioFileName, forKey: "audioFileName")
        transcription.setValue(isFav, forKey: "isFavourite")
        
        do {
            try context.save()
            print("saved!")
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    
    
    func getTranscriptions () -> [NSManagedObject]? {
        
        let fetchRequest: NSFetchRequest<Transcription> = Transcription.fetchRequest()
        
        do {
            let searchResult = try getContext().fetch(fetchRequest)
            print(searchResult.count)
            
            return searchResult as [NSManagedObject]
            
        } catch {
            return nil
        }
    }
    
    func getFavTranscriptions () -> [NSManagedObject]? {
        let fetchRequest: NSFetchRequest<Transcription> = Transcription.fetchRequest()
        
        do {
            let searchResult = try getContext().fetch(fetchRequest)
            var finalResult: [NSManagedObject] = [NSManagedObject]()
            print(searchResult.count)
            
            for transcription in searchResult as [NSManagedObject] {
                if transcription.value(forKey: "isFavourite") as! Bool == true {
                    finalResult.append(transcription)
                }
            }
            
            return finalResult
        } catch {
            print("Error finding fav!")
            return nil
        }
    }
    
    
}
