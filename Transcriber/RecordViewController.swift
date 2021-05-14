//
//  RecordViewController.swift
//  Transcriber
//
//  Created by Sandeep Gautam on 07/05/2021.
//

import UIKit
import AVFoundation
import Speech
import CoreData

class RecordViewController: UIViewController, AVAudioRecorderDelegate {
    
    var audioPlayer: AVAudioPlayer?
    var isRecording: Bool = true
    var titleRecording: String = String()
    
    var transcribed: Bool = false
    var isFavouriteTrans: Bool = false
    
    var flag: Bool = false
    
    var timeOfStart: String = String()
    
    @IBOutlet weak var favourite: UIBarButtonItem!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var buttonStop: UIButton!
    @IBOutlet weak var recordInd: UIActivityIndicatorView!
    
    

    var audioRecorder: AVAudioRecorder?
    var recordedFileURL: URL!
    var textFileURL: URL!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("\(NSHomeDirectory())")
        
        textView.text = ""

        // Do any additional setup after loading the view.
        let utils = Utilities()
        
        timeOfStart = utils.getDateTime()
        
        recordedFileURL = utils.getAudioFilesURL(dateTime: timeOfStart)
        textFileURL = utils.getTextFilesURL(dateTime: timeOfStart)
        
        //print("okchata" + recordedFileURL!.absoluteString)
        
        let alert = UIAlertController(title: "Audio File Action", message: "Enter the name for audio to be recorded", preferredStyle: UIAlertController.Style.alert)
        alert.addTextField { textFieldName in
            textFieldName.placeholder = "Audio name"
            
        }
        alert.addAction(UIAlertAction(title: "Save", style: UIAlertAction.Style.default, handler: { action in
            let titleRec = alert.textFields![0] as UITextField
            self.titleRecording = titleRec.text!
            self.recordAudio()
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
    
    //MARK: audio delegate
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            recordingEnded(success: false)
        } else {
            recordingEnded(success: true)
        }
    }
    
    func recordingEnded (success: Bool) {
        audioRecorder?.stop()
        recordInd.stopAnimating()
        
        UIView.animate(withDuration: 1) {
            self.recordInd.alpha = 0
        }
        
        if success {
            do {
                //playing and transcribing audio
                
                
                
                audioPlayer?.stop()
                audioPlayer = try AVAudioPlayer(contentsOf: recordedFileURL)
                transcribeAudio()
                audioPlayer?.play()
                
                
                buttonStop.isEnabled = true
                buttonStop.setTitle(_ : "Stop Playing", for: .normal)
            } catch let error {
                print(error.localizedDescription)
            }
        }
    }
    
    
    //MARK: audio recording
    
    
    
    @IBAction func onClickFav(_ sender: Any) {
        if isFavouriteTrans {
            isFavouriteTrans = false
            updateBarButton()
        } else if !isFavouriteTrans {
            isFavouriteTrans = true
            updateBarButton()
        }
    }
    
    func updateBarButton() {
        if isFavouriteTrans {
            favourite.image = nil
            UIView.animate(withDuration: 0.25) {
                self.favourite.image = UIImage(systemName: "star.fill")
            }
            
        } else if !isFavouriteTrans {
            favourite.image = nil
            
            UIView.animate(withDuration: 0.25) {
                self.favourite.image = UIImage(systemName: "star")
            }
        }
        
        updateFavourites(isFv: isFavouriteTrans, titRec: titleRecording)
    }
    
    func updateFavourites(isFv: Bool, titRec: String) {
        let results = CoreDataHelper().getTranscriptions()!
        for res in results as [NSManagedObject] {
            if res.value(forKey: "audioFileName") as! String == titRec {
                res.setValue(isFv, forKey: "isFavourite")
                print("set as fav!")
                
            }
        }
        let cntxt = CoreDataHelper().getContext()
        
        do {
            try cntxt.save()
            let alert = UIAlertController(title: "Success", message: "Added to favourites!", preferredStyle: UIAlertController.Style.alert)
            let action = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil)
            alert.addAction(action)
            present(alert, animated: true, completion: nil)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    
    
    @IBAction func onStpRec(_ sender: UIButton) {
        if isRecording {
            audioRecorder?.stop()
            
            let alert = UIAlertController(title: "Recording Stopped", message: "The recording is complete and the file has been saved to your device", preferredStyle: UIAlertController.Style.alert)
            let action = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil)
            alert.addAction(action)
            present(alert, animated: true, completion: nil)
            
            sender.isEnabled = false
            sender.alpha = 0.2
            isRecording = false
        }
        else if !isRecording {
            sender.alpha = 1
            audioPlayer?.stop()
        }
    }
    
    
    func recordAudio () {
        let session = AVAudioSession.sharedInstance()
        
        do {
            try session.setCategory(.playAndRecord, options: .defaultToSpeaker)
            try session.setActive(true)
            
            let settings = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC),AVSampleRateKey: 44100, AVNumberOfChannelsKey: 2, AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]
            
            audioRecorder = try AVAudioRecorder(url: recordedFileURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            recordInd.startAnimating()
            isRecording = true
            
            
        } catch let error {
            print(error.localizedDescription)
            recordingEnded(success: false)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        audioPlayer?.stop()
        //if transcribed {
        let str = recordedFileURL.path
        let stt = textFileURL.path
            let stn = "\(titleRecording)"
            CoreDataHelper().storeTranscription(audioFileURLString: str, textFileURLString: stt, audioFileName: stn, isFav: isFavouriteTrans)
        //}
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: Transcription
    
    func transcribeAudio () {
        let recognizer = SFSpeechRecognizer()
        let request = SFSpeechURLRecognitionRequest(url: recordedFileURL)
        
        recognizer?.recognitionTask(with: request) {
            [unowned self] (result, error) in
            
            guard let result = result else {
                print(error?.localizedDescription)
                return
            }
            
            if result.isFinal {
                let text = result.bestTranscription.formattedString
                self.textView.text = text
                
                do {
                    try text.write(to: self.textFileURL, atomically: true, encoding: String.Encoding.utf8)
                    self.transcribed = true
                } catch {
                    
                }
                
            }
        }
    }
    
    

}
