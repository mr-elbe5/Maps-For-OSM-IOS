/*
 My Private Track
 App for creating a diary with entry based on time and map location using text, photos, audios and videos
 Copyright: Michael Rönnau mr@elbe5.de
 */

import Foundation
import UIKit
import AVFoundation

protocol AudioCaptureDelegate{
    
    func audioCaptured(data: AudioFile)
}

class AudioRecorderViewController : UIViewController, AVAudioRecorderDelegate{
    
    var audioRecorder: AVAudioRecorder? = nil
    var isRecording: Bool = false
    var currentTime: Double = 0.0
    
    var audio = AudioFile()
    
    var bodyView = UIView()
    var closeButtonContainerView = UIView()
    var closeButton = UIButton().asIconButton("xmark.circle", color: .white)
    
    var centerContainerView = UIView()
    var player = AudioPlayerView()
    var recordButton = CaptureButton()
    var saveButton = UIButton()
    var timeLabel = UILabel()
    var progress = AudioProgressView()
    
    var delegate: AudioCaptureDelegate? = nil
    
    init(){
        audio.setFileNameFromId()
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
        view.addSubviewFillingSafeArea(bodyView)
        bodyView.backgroundColor = .black
        
        bodyView.addSubviewWithAnchors(closeButtonContainerView, top: bodyView.topAnchor, trailing: bodyView.trailingAnchor)
            .setRoundedBorders(radius: 5)
            .setBackground(.black)
        
        closeButtonContainerView.addSubviewFilling(closeButton, insets: defaultInsets)
        closeButton.addTarget(self, action: #selector(close), for: .touchDown)
        
        bodyView.addSubviewWithAnchors(centerContainerView, leading: bodyView.leadingAnchor, trailing: bodyView.trailingAnchor)
            .centerY(bodyView.centerYAnchor)
            .setRoundedBorders(radius: 5)
            .setBackground(.darkGray)
    
        timeLabel.textAlignment = .center
        timeLabel.textColor = .white
        centerContainerView.addSubviewWithAnchors(timeLabel, top: centerContainerView.topAnchor, leading: centerContainerView.leadingAnchor, trailing: centerContainerView.trailingAnchor, insets: defaultInsets)
        
        centerContainerView.addSubviewWithAnchors(progress, top: timeLabel.bottomAnchor, leading: centerContainerView.leadingAnchor, trailing: centerContainerView.trailingAnchor, insets: defaultInsets)
        progress.setupView()
        
        centerContainerView.addSubviewWithAnchors(player, top: progress.bottomAnchor, leading: centerContainerView.leadingAnchor, trailing: centerContainerView.trailingAnchor, bottom: centerContainerView.bottomAnchor, insets: defaultInsets)
            .height(100).setBackground(.black)
        player.setupView()
        player.disablePlayer()
        
        saveButton.asTextButton("save".localize(), color: .white)
        saveButton.setTitleColor(.lightGray, for: .disabled)
        saveButton.addTarget(self, action: #selector(save), for: .touchDown)
        bodyView.addSubviewWithAnchors(saveButton, bottom: bodyView.bottomAnchor, insets: defaultInsets)
            .centerX(bodyView.centerXAnchor)
        saveButton.isEnabled = false
        
        recordButton.addTarget(self, action: #selector(toggleRecording), for: .touchUpInside)
        bodyView.addSubviewWithAnchors(recordButton, bottom: saveButton.topAnchor, insets: defaultInsets)
            .centerX(bodyView.centerXAnchor)
            .width(50)
            .height(50)
        
        recordButton.isEnabled = false
        updateTime(time: 0.0)
        AVCaptureDevice.askAudioAuthorization(){ result in
            self.enableRecording()
        }
        
    }
    
    func enableRecording(){
        AudioSession.enableRecording(){result in
            switch result{
            case .success:
                DispatchQueue.main.async {
                    self.recordButton.isEnabled = true
                }
            default:
                break
            }
        }
    }
    
    func startRecording() {
        player.disablePlayer()
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            AVNumberOfChannelsKey: 1,
        ]
        do{
            audioRecorder = try AVAudioRecorder(url: audio.fileURL, settings: settings)
            if let recorder = audioRecorder{
                recorder.isMeteringEnabled = true
                recorder.delegate = self
                recorder.record()
                isRecording = true
                self.recordButton.buttonState = .recording
                DispatchQueue.global(qos: .userInitiated).async {
                    repeat{
                        recorder.updateMeters()
                        DispatchQueue.main.async {
                            self.currentTime = recorder.currentTime
                            self.updateTime(time: self.currentTime)
                            self.updateProgress(decibels: recorder.averagePower(forChannel: 0))
                        }
                        // 1/10s
                        usleep(100000)
                    } while self.isRecording
                }
            }
        }
        catch{
            recordButton.isEnabled = false
        }
    }
    
    func finishRecording(success: Bool) {
        isRecording = false
        audioRecorder?.stop()
        audioRecorder = nil
        if success {
            player.url = audio.fileURL
            player.enablePlayer()
            audio.time = (self.currentTime*100).rounded() / 100
        } else {
            player.disablePlayer()
            player.url = nil
        }
        recordButton.buttonState = .normal
        saveButton.isEnabled = true
    }
    
    func updateTime(time: Double){
        timeLabel.text = String(format: "%.02f s", time)
    }
    
    func updateProgress(decibels: Float){
        progress.setProgress((min(max(-60.0, decibels),0) + 60.0) / 60.0)
    }
    
    @objc func toggleRecording() {
        if audioRecorder == nil {
            startRecording()
        } else {
            finishRecording(success: true)
        }
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: flag)
        }
    }
    
    @objc func save(){
        delegate?.audioCaptured(data: audio)
        self.dismiss(animated: true, completion: {
        })
    }
    
    @objc func close(){
        self.dismiss(animated: true, completion: {
        })
    }
    
}

class AudioSession{
    
    static var isEnabled = false
    
    static func enableRecording(callback: @escaping (Result<Void, Error>) -> Void){
        if isEnabled{
            callback(.success(()))
        }
        else{
            AVCaptureDevice.askAudioAuthorization(){ result in
                switch result{
                case .success(()):
                    do {
                        let session = AVAudioSession.sharedInstance()
                        try session.setCategory(.playAndRecord, mode: .default)
                        try session.overrideOutputAudioPort(.speaker)
                        try session.setActive(true)
                        session.requestRecordPermission() { allowed in
                            isEnabled = true
                            callback(.success(()))
                        }
                    } catch {
                        callback(.failure(NSError()))
                    }
                    return
                case .failure:
                    callback(.failure(NSError()))
                    return
                }
            }
        }
    }
    
}

class AudioProgressView : UIView{
    
    var lowLabel = UIImageView(image: UIImage(systemName: "speaker"))
    var progress = UIProgressView()
    var loudLabel = UIImageView(image: UIImage(systemName: "speaker.3"))
    
    func setupView() {
        backgroundColor = .black
        lowLabel.tintColor = .white
        addSubviewWithAnchors(lowLabel, top: topAnchor, leading: leadingAnchor, bottom: bottomAnchor, insets: defaultInsets)
        progress.progressTintColor = .systemRed
        progress.progress = 0.0
        addSubviewWithAnchors(progress, top: topAnchor, leading: lowLabel.trailingAnchor, bottom: bottomAnchor, insets: defaultInsets)
        loudLabel.tintColor = .white
        addSubviewWithAnchors(loudLabel, top: topAnchor, leading: progress.trailingAnchor, trailing: trailingAnchor, bottom: bottomAnchor, insets: defaultInsets)
    }
    
    func setProgress(_ value: Float){
        progress.setProgress(value, animated: true)
    }
    
}
