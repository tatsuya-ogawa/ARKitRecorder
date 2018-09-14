//
//  ViewController.swift
//  ARRecorder
//
//  Created by Guanqi Yu on 26/6/17.
//  Copyright © 2017 Guanqi Yu. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    @IBOutlet weak var recordButton: UIButton!
    
//    var jsonObject = [String:FrameInfo]()
//    var recordStartTime: String?
    
//    enum RecordingState {
//        case recording
//        case notRecording
//    }
    
//    var currentState = RecordingState.notRecording
//    var previousState = RecordingState.notRecording
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.session.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        //other sceneView configuration
        sceneView.preferredFramesPerSecond = 30
        sceneView.automaticallyUpdatesLighting = false
//        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        
        // Create a new scene
//        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        
        // Set the scene to the view
//        sceneView.scene = scene
        
        //register tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ViewController.handleTap(gestureRecognize:)))
        sceneView.addGestureRecognizer(tapGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    // MARK: - Handle Tap
    
    @objc
    func handleTap(gestureRecognize: UITapGestureRecognizer) {
        
        
    }
    
    class ARPointCloud :Codable{
        var count : Int!
        var points : [[Float]]!
        init() {
        }
    }
    class FrameInfo:Codable{
        var imageName : String!
        var timeStamp :TimeInterval!
        var cameraPos : [String:Float]!
        var cameraEulerAngle :[String:Float]!
        var cameraTransform:[[Float]]!
        var cameraIntrinsics:[[Float]]!
        var imageResolution:[String:CGFloat]!
        var lightEstimate : CGFloat!
        var ARPointCloud :ARPointCloud?
        init() {
        }
    }
    
    func currentFrameInfoToDic(currentFrame: ARFrame) -> FrameInfo {
        
        let currentTime:String = String(format:"%f", currentFrame.timestamp)
        let imageName = currentTime + ".jpg"
        let frameInfo = FrameInfo()
        frameInfo.imageName = imageName
        frameInfo.timeStamp = currentFrame.timestamp
        frameInfo.cameraPos = dictFromVector3(positionFromTransform(currentFrame.camera.transform))
        frameInfo.cameraEulerAngle = dictFromVector3(currentFrame.camera.eulerAngles)
        frameInfo.cameraTransform  = arrayFromTransform(currentFrame.camera.transform)
        frameInfo.cameraIntrinsics = arrayFromTransform(currentFrame.camera.intrinsics)
        frameInfo.imageResolution = [
            "width": currentFrame.camera.imageResolution.width,
            "height": currentFrame.camera.imageResolution.height
        ]
        frameInfo.lightEstimate = (currentFrame.lightEstimate?.ambientIntensity)!
        let arPointCloud = ARPointCloud()
        arPointCloud.count = (currentFrame.rawFeaturePoints?.__count) ?? 0
        arPointCloud.points = arrayFromPointCloud(currentFrame.rawFeaturePoints)
        frameInfo.ARPointCloud = arPointCloud
        return frameInfo
//        let jsonObject: [String: Any] = [
//            "imageName": imageName,
//            "timeStamp": currentFrame.timestamp,
//            "cameraPos": dictFromVector3(positionFromTransform(currentFrame.camera.transform)),
//            "cameraEulerAngle": dictFromVector3(currentFrame.camera.eulerAngles),
//            "cameraTransform": arrayFromTransform(currentFrame.camera.transform),
//            "cameraIntrinsics": arrayFromTransform(currentFrame.camera.intrinsics),
//            "imageResolution": [
//                "width": currentFrame.camera.imageResolution.width,
//                "height": currentFrame.camera.imageResolution.height
//            ],
//            "lightEstimate": currentFrame.lightEstimate?.ambientIntensity,
//            "ARPointCloud": [
//                "count": currentFrame.rawFeaturePoints?.count,
//                "points": arrayFromPointCloud(currentFrame.rawFeaturePoints)
//            ]
//        ]
//
//        return jsonObject
    }
    let queue = DispatchQueue(label:"frame",qos: .background)
    // MARK: - ARSessionDelegate
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
        if recordButton!.isHighlighted {
            let jsonNode = self.currentFrameInfoToDic(currentFrame: frame)
            queue.async {
                let recordStartTime = getCurrentTime()
                var jsonObject = [String:FrameInfo]()

                jsonObject[jsonNode.imageName] = jsonNode
                let jpgImage = UIImageJPEGRepresentation(pixelBufferToUIImage(pixelBuffer: frame.capturedImage), 1.0)
                let path = getFilePath(fileFolder: recordStartTime, fileName: jsonNode.imageName)
                try? jpgImage?.write(to: URL(fileURLWithPath:path ))

                let data = try! JSONEncoder().encode(jsonObject)
                let json = String(data: data, encoding: String.Encoding.utf8)!
                let jsonFilePath = getFilePath(fileFolder: recordStartTime, fileName: getCurrentTime()+".json")
                do {
                    try json.write(toFile: jsonFilePath, atomically: false, encoding: String.Encoding.utf8)
                    print("write json succeed...")
                }catch {
                        print("write json failed...")
                }
            }
        }
//        previousState = currentState
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
