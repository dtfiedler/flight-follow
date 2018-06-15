//
//  ViewController.swift
//  FlightFollow
//
//  Created by Dylan Fiedler on 2018/16/4.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    @IBOutlet weak var maskedImage: UIImageView!
    @IBOutlet weak var imageView: UIImageView!
	var session: AVCaptureSession!
	var device: AVCaptureDevice!
	var output: AVCaptureVideoDataOutput!
	
    
	override func viewDidLoad() {
		super.viewDidLoad()
        //ask user if they want to view output
        setupCamera()
        //hide nav bar on tap
        navigationController?.hidesBarsOnTap = true
    }
    
    override var prefersStatusBarHidden: Bool {
        return navigationController?.isNavigationBarHidden == true
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return UIStatusBarAnimation.slide
    }

	override var shouldAutorotate : Bool {
		return false
	}
    
    func setupCamera(){
        //create an AVSession to capture camera output
        self.session = AVCaptureSession()
        self.session.sessionPreset = AVCaptureSession.Preset.vga640x480
        self.device = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back)
        if (self.device == nil) {
            print("ERROR: Device not available")
            return
        }
        do {
            //access front facing camera input
            let input = try AVCaptureDeviceInput(device: self.device)
            self.session.addInput(input)
        } catch {
            print("ERROR: NO DEVICE INPUT FOUND")
            return
        }
        
        //we will modify this output once the camera is displaying output
        self.output = AVCaptureVideoDataOutput()
        //make the video settings bugger as pixel
        self.output.videoSettings = [ kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA) ]
        //async video capture to add
        let queue: DispatchQueue = DispatchQueue(label: "videocapturequeue", attributes: [])
        self.output.setSampleBufferDelegate(self, queue: queue)
        self.output.alwaysDiscardsLateVideoFrames = true
        if self.session.canAddOutput(self.output) {
            self.session.addOutput(self.output)
        } else {
            print("could not add a session output")
            return
        }
        do {
            //DON'T LET IT ROTATE
            try self.device.lockForConfiguration()
            //Default to 20fps
            self.device.activeVideoMinFrameDuration = CMTimeMake(1, 20) // 20 fps
            self.device.unlockForConfiguration()
        } catch {
            print("could not configure a device")
            return
        }
    
        self.session.startRunning()
    }

	func captureOutput(_ captureOutput: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
		
        //create buffer
		guard let buffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("ERROR: unable to get buffer")
			return
		}
		let capturedImage: UIImage
		do {
            //lock, need defer so it can release and recatpure
			CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags.readOnly)
			defer {
				CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags.readOnly)
			}
            //need to create context to be able to draw on
			let address = CVPixelBufferGetBaseAddressOfPlane(buffer, 0)
			let bytes = CVPixelBufferGetBytesPerRow(buffer)
			let width = CVPixelBufferGetWidth(buffer)
			let height = CVPixelBufferGetHeight(buffer)
			let color = CGColorSpaceCreateDeviceRGB()
			let bits = 8
			let info = CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
			guard let context = CGContext(data: address, width: width, height: height, bitsPerComponent: bits, bytesPerRow: bytes, space: color, bitmapInfo: info) else {
                print("ERROR:could not create an CGContext")
				return
			}
			guard let image = context.makeImage() else {
				print("could not create an CGImage")
				return
			}
            //get caputred image
			capturedImage = UIImage(cgImage: image, scale: 1.0, orientation: UIImageOrientation.right)
		}
		
        //first one shows the path of the ball
        let outputImage = OpenCV.trackBall(withColor: capturedImage, "WHITE")
        //show the mask so we can see what is being track
        let maskedImage = OpenCV.getMaskedImage(capturedImage)
		// display the result on the output, as well as the imageview mask
		DispatchQueue.main.async(execute: {
			self.imageView.image = outputImage
            self.maskedImage.image = maskedImage;
		})
	}
}

