//
//  ViewController.swift
//  CoreMLInseptionSample
//
//  Created by yudoufu on 2017/07/22.
//  Copyright © 2017年 Personal. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var classLabel: UILabel!

    private let network = Inceptionv3()
    private var cameraCapture: CameraCapture!

    override func viewDidLoad() {
        super.viewDidLoad()
        cameraCapture = CameraCapture(parentLayer: mainView.layer, fps: 3) { [weak self] imageBuffer in
            self?.predictImageBuffer(imageBuffer)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cameraCapture.startSession()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cameraCapture.stopSession()
    }

    private func predictImageBuffer(_ imageBuffer: CVPixelBuffer) {
        guard let resizedBuffer = resize(pixelBuffer: imageBuffer, newSize: CGSize(width: 299, height: 299)) else {
            fatalError("Resize error")
        }
        guard let output = try? network.prediction(image: resizedBuffer) else {
            fatalError("Prediction error")
        }

        classLabel.text = output.classLabel
        print(output.classLabel)
    }

    private func resize(pixelBuffer: CVPixelBuffer, newSize: CGSize) -> CVPixelBuffer? {
        let beforeImage = CIImage(cvPixelBuffer: pixelBuffer, options: nil)
        let transform = CGAffineTransform(
            scaleX: CGFloat(newSize.width) / CGFloat(CVPixelBufferGetWidth(pixelBuffer)),
            y: CGFloat(newSize.height) / CGFloat(CVPixelBufferGetHeight(pixelBuffer))
        )

        let ciImage = beforeImage
            .transformed(by: transform)
            .cropped(to: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))

        var resizeBuffer: CVPixelBuffer?
        CVPixelBufferCreate(kCFAllocatorDefault, Int(newSize.width), Int(newSize.height), CVPixelBufferGetPixelFormatType(pixelBuffer), nil, &resizeBuffer)
        CIContext().render(ciImage, to: resizeBuffer!)

        return resizeBuffer
    }
}

