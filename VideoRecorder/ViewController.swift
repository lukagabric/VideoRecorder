//
//  ViewController.swift
//  VideoRecorder
//
//  Created by Luka Gabric on 05/08/2017.
//  Copyright © 2017 Luka Gabric. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

class ViewController: UIViewController {
	
	//MARK: - Vars
	
	private let captureService: CaptureService
	private let previewLayer: AVCaptureVideoPreviewLayer
	
	@IBOutlet private weak var playButton: UIButton!
	@IBOutlet private weak var recordButton: UIButton!
	@IBOutlet private weak var previewContainer: UIView!
	
	private var player: AVPlayer?
	private var playerLayer: AVPlayerLayer?
	
	//MARK: - Init
	
	init() {
		self.captureService = CaptureService(position: .front)
		self.previewLayer = self.captureService.previewLayer
		self.previewLayer.videoGravity = .resizeAspectFill
		super.init(nibName: "ViewController", bundle: nil)
		
		NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	//MARK: - View Lifecycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.setButtonsEnabled(false)
		
		self.previewContainer.layer.addSublayer(self.previewLayer)
		
		self.checkPermissionAndRecord()
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		self.previewLayer.frame = self.previewContainer.bounds
	}
	
	//MARK: - Permissions
	
	private func checkPermissionAndRecord() {
		switch AVCaptureDevice.authorizationStatus(for: .video) {
		case .authorized:
			self.checkAudioPermissionAndRecord()
		case .notDetermined:
			self.requestVideoPermission()
		default: break
		}
	}
	
	private func requestVideoPermission() {
		AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
			guard let sself = self, granted == true else { return }
			DispatchQueue.main.async {
				sself.checkAudioPermissionAndRecord()
			}
		}
	}
	
	private func checkAudioPermissionAndRecord() {
		switch AVCaptureDevice.authorizationStatus(for: .audio) {
		case .authorized:
			self.setButtonsEnabled(true)
		case .notDetermined:
			self.requestAudioPermission()
		default: break
		}
	}
	
	private func requestAudioPermission() {
		AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
			guard let sself = self, granted == true else { return }
			DispatchQueue.main.async {
				sself.setButtonsEnabled(true)
			}
		}
	}
	
	private func setButtonsEnabled(_ enabled: Bool) {
		self.recordButton.isEnabled = enabled
		self.playButton.isEnabled = enabled
	}
	
	//MARK: - User Interaction
	
	@IBAction func recordAction(_ sender: Any) {
		self.freePreview()
		self.setButtonsEnabled(false)

		self.captureService.startRecording(fileURL: self.createFileUrl())
		DispatchQueue.main.asyncAfter(wallDeadline: .now() + 3) {
			self.captureService.stopRecording()
			
			self.setButtonsEnabled(true)
		}
	}

	@IBAction func playAction(_ sender: Any) {
		self.freePreview()
		
		let videoURL = self.createFileUrl()

		let player = AVPlayer(url: videoURL)
		let playerLayer = AVPlayerLayer(player: player)
		
		self.player = player
		self.playerLayer = playerLayer
		
		playerLayer.frame = self.previewContainer.bounds
		playerLayer.videoGravity = .resizeAspectFill
		
		self.previewContainer.layer.addSublayer(playerLayer)
		
		player.play()
	}
	
	@objc func playerDidFinishPlaying() {
		self.freePreview()
	}
	
	private func freePreview() {
		self.player?.pause()
		self.playerLayer?.removeFromSuperlayer()
		self.playerLayer = nil
		self.player = nil
	}
	
	private func createFileUrl() -> URL {
		let documentsUrl = FileManager.default.urls(for: .cachesDirectory, in:.userDomainMask).first!
		let videoUrl = documentsUrl.appendingPathComponent("video12.mov")
		return videoUrl
	}
	
	//MARK: -
	
}
