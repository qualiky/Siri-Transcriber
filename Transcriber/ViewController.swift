//
//  ViewController.swift
//  Transcriber
//
//  Created by Sandeep Gautam on 06/05/2021.
//

import UIKit
import AVFoundation
import Speech

class ViewController: UIViewController {

    @IBOutlet weak var warningLabel: UILabel!
    @IBOutlet weak var permissionsButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Do any additional setup after loading the view.
    }


    func requestForRecordPermission () {
        AVAudioSession.sharedInstance().requestRecordPermission() {
            [unowned self] allowed in
            DispatchQueue.main.async {
                if allowed {
                    self.requestForTranscribePermission()
                } else {
                    warningLabel.text = "Permission has not been granted. Please go to settings and provide the necessary Record permission to use this app."
                }
            }
        }
    }
    
    func requestForTranscribePermission () {
        SFSpeechRecognizer.requestAuthorization {
            [unowned self] allowed in
            DispatchQueue.main.async {
                if SFSpeechRecognizer.authorizationStatus() == .authorized {
                    self.dismiss(animated: true, completion: nil)
                } else {
                    warningLabel.text = "Permission has not been granted. Please go to settings and provide the necessary Speech permission to use this app."
                    permissionsButton.isEnabled = false
                    UIButton.animate(withDuration: 1.0) {
                        permissionsButton.alpha = 0.3
                    }
                }
            }
        }
    }
    
    @IBAction func onClickPermissions(_ sender: UIButton) {
        requestForRecordPermission()
    }
}

