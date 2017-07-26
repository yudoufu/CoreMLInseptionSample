//
//  CameraCapture.swift
//  CoreMLInseptionSample
//
//  Created by yudoufu on 2017/07/22.
//  Copyright © 2017年 Personal. All rights reserved.
//

import Foundation
import AVFoundation

class CameraCapture: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    typealias ImageBufferHandler = ((CVImageBuffer) -> Void)


    private let session = AVCaptureSession()
    private let fps: CMTimeScale
    private let parentLayer: CALayer?
    private let imageBufferHandler: ImageBufferHandler?

    private var camera: AVCaptureDevice!
    private var previewLayer: AVCaptureVideoPreviewLayer?

    init(parentLayer: CALayer?, fps: CMTimeScale = 20, completionHandler: ImageBufferHandler?) {
        self.parentLayer = parentLayer
        self.imageBufferHandler = completionHandler
        self.fps = fps

        super.init()

        setupCamera()
    }

    private func setupCamera() {
        guard let camera = AVCaptureDevice.default(for: .video) else {
            print("no camera")
            return
        }
        self.camera = camera

        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .authorized:
            connectSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] authorized in
                if authorized {
                    self?.connectSession()
                }
            }
        case .restricted, .denied:
            print("camera not autherized")
        }
    }

    private func connectSession() {
        do {
            try setVideoInput()
            setVideoOutput()
            setupPreviewLayer()
        } catch let error as NSError {
            print(error)
        }
    }

    private func setVideoInput() throws {
        let videoInput = try AVCaptureDeviceInput(device: camera)

        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        }

        do {
            try camera.lockForConfiguration()
            camera.activeVideoMinFrameDuration = CMTime(value: 1, timescale: fps)
            camera.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: fps)
            camera.unlockForConfiguration()
        } catch {
            fatalError()
        }
    }

    private func setVideoOutput() {
        let videoOutput = AVCaptureVideoDataOutput()

        // ここはBGRAに変換しておかないといけない(画像認識のinput interfaceの関係)
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable as! String: NSNumber(value: kCVPixelFormatType_32BGRA)]
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)

        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
    }

    private func setupPreviewLayer() {
        guard previewLayer == nil else {
            print("preview layer already exist")
            return
        }
        guard let parentLayer = parentLayer else {
            print("parent layer doesn't exist")
            return
        }
        let layer = AVCaptureVideoPreviewLayer(session: session)

        layer.frame = parentLayer.bounds
        layer.contentsGravity = kCAGravityResizeAspectFill
        layer.videoGravity = .resizeAspectFill

        parentLayer.addSublayer(layer)
        previewLayer = layer
    }

    func startSession() {
        if !session.isRunning {
            session.startRunning()
        }
    }

    func stopSession() {
        if session.isRunning {
            session.stopRunning()
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if let imageBufferHandler = imageBufferHandler, let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            imageBufferHandler(buffer)
        }
    }
}

