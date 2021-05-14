//
//  PlayViewController.swift
//  Transcriber
//
//  Created by Sandeep Gautam on 11/05/2021.
//

import UIKit
import Foundation
import AVKit
import CoreData
import AVFAudio

class PlayViewController: UIViewController, AVAudioPlayerDelegate {
    
    var item: NSManagedObject!

    @IBOutlet weak var recordingTitle: UILabel!
    @IBOutlet weak var audioSlider: UISlider!
    @IBOutlet weak var btnRewind: UIButton!
    @IBOutlet weak var btnForward: UIButton!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var totalTimeLabel: UILabel!
    @IBOutlet weak var btnPlayPause: UIButton!
    @IBOutlet weak var labelTranscription: UILabel!
    @IBOutlet weak var textViewTranscription: UITextView!
    @IBOutlet weak var btnEdit: UIBarButtonItem!
    @IBOutlet weak var favButton: UIButton!
    
    var textFileURL: URL!
    var audioFileURL: URL!
    var audioPlayer: AVAudioPlayer?
    var transcriptions: [NSManagedObject]? = [NSManagedObject]()
    var audioTitleName: String!
    
    var isPlayingAudio: Bool = false
    var canEditTranscription: Bool = false
    var isEditingText: Bool = false
    var editedTranscription: String!
    var isFav: Bool = false
    var updater: CADisplayLink! = nil
    
    var successfullyEdited: Bool = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadDataFromItem()
        // Do any additional setup after loading the view.
    }
    
    func loadDataFromItem () {
        
        //load top title of the page
        if let name = item?.value(forKey: "audioFileName") {
            if name as! String == "" {
                recordingTitle?.text = "Unnamed recording"
            } else {
                recordingTitle?.text = "\(name)"
                audioTitleName = name as! String
            }
        }
        
        //see if this thing is starred
        if let isStarred = item?.value(forKey: "isFavourite") {
            if isStarred as! Bool == true {
                favButton.setImage(UIImage(systemName: "star.fill"), for: UIControl.State.normal)
                isFav = true
            } else if isStarred as! Bool == false {
                favButton.setImage(UIImage(systemName: "star"), for: UIControl.State.normal)
            }
        }
        
        //load transcriptions to the textview below
        if let textFileURLFromCoreData = item?.value(forKey: "textFileURLString") {
            if let textFileString = textFileURLFromCoreData as? String {
                textFileURL = URL(fileURLWithPath: textFileString)
            }
        }
        
        do {
            let contentsFromFile: String = try String(contentsOf: textFileURL, encoding: String.Encoding.utf8)
            print(contentsFromFile)
            if contentsFromFile == "" {
                textViewTranscription.text = "Uhh...couldn't find any transcription"
            } else {
                textViewTranscription.text = contentsFromFile
                canEditTranscription = true
            }
        } catch {
            print(error.localizedDescription)
        }
        
        //time to load the audio!
        //load audio
        
        if let audioFileURLFromCoreData = item?.value(forKey: "audioFileURLString") {
            if let audioFileString = audioFileURLFromCoreData as? String {
                audioFileURL = URL(fileURLWithPath: audioFileString)
            }
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioFileURL)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            updater = CADisplayLink(target: self, selector: #selector(trackAudio))
            updater.preferredFramesPerSecond = 1
            updater.add(to: RunLoop.current, forMode: RunLoop.Mode.common)
            audioPlayer?.volume = 0.5
            
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        player.stop()
        isPlayingAudio = false
        updatePlayIcon()
        updater.invalidate()
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onFavButtonClick(_ sender: Any) {
        if isFav {
            if let results = CoreDataHelper().getTranscriptions() {
                transcriptions = results
            }
            for transc in transcriptions! as [NSManagedObject] {
                if transc.value(forKey: "audioFileName") as? String == audioTitleName {
                    transc.setValue(isFav, forKey: "isFavourite")
                    UIView.animate(withDuration: 0.25) {
                        self.favButton.setImage(UIImage(systemName: "star.fill"), for: UIControl.State.normal)
                    }
                }
            }
        }
        
        else if !isFav {
            if let results = CoreDataHelper().getTranscriptions() {
                transcriptions = results
            }
            for transc in transcriptions! as [NSManagedObject] {
                if transc.value(forKey: "audioFileName") as? String == audioTitleName {
                    transc.setValue(isFav, forKey: "isFavourite")
                    UIView.animate(withDuration: 0.25) {
                        self.favButton.setImage(UIImage(systemName: "star"), for: UIControl.State.normal)
                    }
                }
            }
        }
    }
    
    @IBAction func onEditClick(_ sender: UIBarButtonItem) {
        if canEditTranscription && !isEditingText {
            textViewTranscription.isEditable = true
            isEditingText = true
            btnEdit.title = "Save"
        }
        else if isEditingText {
            editedTranscription = textViewTranscription.text
            let isSaved = saveData()
        }
    }
    
    func saveData () -> Bool {
        if let results = CoreDataHelper().getTranscriptions() {
            transcriptions = results
        }
        for transc in transcriptions! as [NSManagedObject] {
            if transc.value(forKey: "audioFileName") as? String == audioTitleName {
                do {
                    try editedTranscription.write(to: textFileURL, atomically: false, encoding: String.Encoding.utf8)
                    successfullyEdited = true
                    
                } catch {
                    print(error.localizedDescription)
                    let alert = UIAlertController(title: "Error", message: "Could not save edited transcription", preferredStyle: UIAlertController.Style.alert)
                    let action = UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil)
                    alert.addAction(action)
                    present(alert, animated: true, completion: nil)
                }
            }
        }
        return successfullyEdited
    }
    
    
    @IBAction func onFastForwardClick(_ sender: Any) {
    }
    
    
    @IBAction func onRewindClick(_ sender: Any) {
    }
    
    
    @IBAction func onPlayPauseClick(_ sender: Any) {
        if !isPlayingAudio {
            audioPlayer?.play()
            updateSlider()
            isPlayingAudio = true
            updatePlayIcon()
        } else if isPlayingAudio {
            audioPlayer?.pause()
            audioSlider.value = Float(audioPlayer!.currentTime)
            isPlayingAudio = false
            updatePlayIcon()
        }
    }
    
    func updateSlider() {
        currentTimeLabel.text =  String(audioPlayer!.currentTime)
        totalTimeLabel.text = String(audioPlayer!.duration)
        audioSlider.minimumValue = 0
        audioSlider.maximumValue = 100
    }
    
    @objc func trackAudio () {
        var normalizedTime = Float((audioPlayer!.currentTime) * 100 / audioPlayer!.duration)
        audioSlider.value = normalizedTime
        
    }
    
    func updatePlayIcon () {
        if isPlayingAudio {
            btnPlayPause.setImage(nil, for: .normal)
            
            UIView.animate(withDuration: 0.25) {
                self.btnPlayPause.setImage(UIImage(systemName: "pause.fill"), for: UIControl.State.normal)
            }
        } else if !isPlayingAudio {
            btnPlayPause.setImage(nil, for: UIControl.State.normal)
            
            UIView.animate(withDuration: 0.25) {
                self.btnPlayPause.setImage(UIImage(systemName: "play.fill"), for: UIControl.State.normal)
            }
        }
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
