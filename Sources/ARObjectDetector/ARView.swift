//
//  ARView.swift
//  ARObjectRecognizer
//
//  Created by meekam.okeke on 7/28/22.
//

import Foundation
import ARKit
import SwiftUI

struct ARView: UIViewControllerRepresentable {
    typealias UIViewControllerType = ARViewController
    
    func makeUIViewController(context: Context) -> ARViewController {
        return ARViewController()
    }
    
    func updateUIViewController(_ uiViewController: ARView.UIViewControllerType, context: Context) {
        //
    }
}

final class ARViewController: UIViewController, ARSCNViewDelegate {
    
    private var currentBuffer: CVPixelBuffer?
    
    private var _mlObjectModel: MLObjectDetection!
    
    private var mlObjectModel: MLObjectDetection! {
        get {
            if let model = _mlObjectModel {
                return model
            }
            
            _mlObjectModel = {
                do {
                    let config = MLModelConfiguration()
                    return try MLObjectDetection(configuration: config)
                } catch {
                    fatalError("An error occured while processing your model object/class")
                }
            }()
            return _mlObjectModel
        }
    }
    
    private let visionQueue = DispatchQueue(label: "com.ARObjectRecognizer.serialVisionQueue")
    
    var arView: ARSCNView {
        return self.view as! ARSCNView
    }
    
    override func loadView() {
        self.view = ARSCNView(frame: .zero)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        arView.delegate          = self
        arView.session.delegate  = self
        arView.scene             = SCNScene()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        arView.session.run(configuration)
        arView.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        arView.session.pause()
    }
    
    private lazy var classificationRequest: VNCoreMLRequest = {
        do {
            let model = try VNCoreMLModel(for: mlObjectModel.model)
            let request = VNCoreMLRequest(model: model) { [weak self] request, error in
                self?.processClassificationRequest(request, error)
            }
            
            request.imageCropAndScaleOption = .centerCrop
            request.usesCPUOnly = true
            return request
        }
        catch {
            fatalError("Error processing request")
        }
    }()
    
    private func processClassificationRequest(_ request: VNRequest, _ error: Error?) {
        guard let results = request.results else {
            return
        }
        
        let classificationResults = results as! [VNClassificationObservation]
        
        var objectName = ""
        var confidence: VNConfidence = 0.0
        if let baseResult = classificationResults.first(where: { result in result.confidence > 0.5 }), let
            label = baseResult.identifier.split(separator: ",").first {
            objectName = String(label)
            confidence = baseResult.confidence
        }
        
        DispatchQueue.main.async { [weak self] in
          self?.sendNotification(objectName, confidence)
        }
    }
    
    private func sendNotification(_ objectName: String, _ confidence: VNConfidence) {
        if (objectName.isEmpty) {
            return
        }
        let appMessage = NotificationMessage(objectName: objectName, confidence: confidence * 100)
        NotificationCenter.default.post(name: Notification.AppMessage, object: appMessage)
    }
    
    private func classifyCurrentImage() {
        let orientation = CGImagePropertyOrientation(UIDevice.current.orientation)
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: currentBuffer!, orientation: orientation)
        visionQueue.async {
            do {
                defer { self.currentBuffer = nil }
                try requestHandler.perform([self.classificationRequest])
            } catch {
                print("Error: vision request failed with error\"\(error)")
            }
        }
    }
}

extension ARViewController:  ARSessionDelegate {
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard currentBuffer == nil, case .normal = frame.camera.trackingState else {
            return
        }
        
        self.currentBuffer = frame.capturedImage
        self.classifyCurrentImage()
    }
}

