//
//  Utilities.swift
//  ARObjectRecognizer
//
//  Created by meekam.okeke on 7/28/22.
//

import Foundation
import ARKit

extension CGImagePropertyOrientation {
    init(_ deviceOrientation: UIDeviceOrientation) {
        switch deviceOrientation {
        case .portraitUpsideDown: self = .left
        case .landscapeLeft: self      = .up
        case .landscapeRight: self     = .down
        default: self                  = .right
        }
    }
}

extension Notification {
    static let AppMessage = Notification.Name("AppMessage")
}

struct NotificationMessage {
    let objectName: String
    let confidence: Float
}

private class ARObjectDetectorBundleFinder {}

extension Foundation.Bundle {
    static var arObjectDetectorModule: Bundle =  {
        let  bundleName = "ARObjectDetector_ARObjectDetector"
        let localBundleName = "LocalPackages_ARObjectDetector"
        
        let candidates = [
            Bundle.main.resourceURL,
            Bundle(for: ARObjectDetectorBundleFinder.self).resourceURL,
            Bundle.main.bundleURL,
            Bundle(for:
                    ARObjectDetectorBundleFinder.self).resourceURL?.deletingLastPathComponent()
                .deletingLastPathComponent().deletingLastPathComponent(),
            Bundle(for: ARObjectDetectorBundleFinder.self).resourceURL?.deletingLastPathComponent().deletingLastPathComponent(),
        ]
        
        for candidate in candidates {
            let bundlePath = candidate?.appendingPathComponent(bundleName + ".bundle")
            if let bundle = bundlePath.flatMap(Bundle.init(url:)) {
                return bundle
            }
            
            let localBundlePath = candidate?.appendingPathComponent(localBundleName + ".bundle")
            if let bundle = bundlePath.flatMap(Bundle.init(url:)) {
                return bundle
            }
        }
        fatalError("unable to find bundle")
    }()
}
