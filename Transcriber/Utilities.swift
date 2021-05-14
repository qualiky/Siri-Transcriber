//
//  Utilities.swift
//  Transcriber
//
//  Created by Sandeep Gautam on 07/05/2021.
//

import Foundation

class Utilities {
    
    var dateTimeString: String?
    
    func getDocsDirectory () -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let docsDirectory = paths[0]
        return docsDirectory
    }
    
    func getAudioFilesURL (dateTime: String) -> URL? {
        let audioURL = getDocsDirectory().appendingPathComponent(dateTime + ".m4a")
        return audioURL
    }
    
    func getTextFilesURL (dateTime: String) -> URL? {
        let textURL = getDocsDirectory().appendingPathComponent(dateTime + ".txt")
        return textURL
    }
    
    func getDateTime () -> String {
        
        if let dateT = dateTimeString {
            return dateT
        }
        
        let date = Date()
        
        let dF = DateFormatter()
        dF.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        let timeString = dF.string(from: date)
        return timeString
    }
}
