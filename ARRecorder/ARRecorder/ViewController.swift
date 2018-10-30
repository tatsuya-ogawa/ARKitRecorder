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
import AVFoundation

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
//    private var videoCapture: VideoCapture!
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
        
        let tapButtonGesture = UITapGestureRecognizer(target: self, action: #selector(ViewController.handleButtonTap(gestureRecognize:)))
        recordButton.addGestureRecognizer(tapButtonGesture)
        
//        videoCapture = VideoCapture(cameraType: .back(true),
//                                    preferredSpec: nil,
//                                    previewContainer: nil)
//
//        videoCapture.syncedDataBufferHandler = { [weak self] videoPixelBuffer, depthData, face in
//            guard let self = self else { return }
//            let videoImage = CIImage(cvPixelBuffer: videoPixelBuffer)
//        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
//        let configuration = ARWorldTrackingConfiguration()
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        // Run the view's session
        sceneView.session.run(configuration)
        
//        guard let videoCapture = videoCapture else {return}
//        videoCapture.startCapture()
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
    var recordingFlag = false
    var recordTime = Date()
    @objc
    func handleButtonTap(gestureRecognize: UITapGestureRecognizer) {
        if recordingFlag{
            recordButton.backgroundColor = UIColor.white
            recordingFlag = false
        }else{
            recordButton.backgroundColor = UIColor.red
            recordingFlag = true
        }
    }

    
    class ARPointCloud :Codable{
        var count : Int!
        var points : [[Float]]!
        init() {
        }
    }
    struct Vector3:Codable{
        let x:Float
        let y:Float
        let z:Float
        init(_ scn:SCNVector3) {
            self.x = scn.x
            self.y = scn.y
            self.z = scn.z
        }
        init(_ x:Float,_ y:Float,_ z:Float){
            self.x = x
            self.y = y
            self.z = z
        }
    }
    class CenterPosition:Codable{
        var worldPos:Vector3!
        var hitPos:Vector3!
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
        var centerPos:CenterPosition?
        init() {
        }
    }
    func getCentorPosition()->CenterPosition{
        let ret = CenterPosition()
        
        let screenBounds = UIScreen.main.bounds
        let centerPos = CGPoint(x:screenBounds.midX,y:screenBounds.midY)
        let centerVec3 = SCNVector3Make(Float(centerPos.x),Float(centerPos.y),0.99)
        let worldPos = sceneView.unprojectPoint(centerVec3)
        ret.worldPos = Vector3(worldPos)
        
        let results = sceneView.hitTest(centerPos, types: [.estimatedVerticalPlane,.estimatedHorizontalPlane])
        if let nearlest = results.first{
            let columns = nearlest.worldTransform.columns
            ret.hitPos = Vector3(columns.3.x,columns.3.y,columns.3.z)
        }
        return ret
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
        
        frameInfo.centerPos = getCentorPosition()
        
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
    
    func beep(){
        var soundId:SystemSoundID = 0
        if let soundUrl:NSURL = NSURL(fileURLWithPath: "/System/Library/Audio/UISounds/alarm.caf") {
            AudioServicesCreateSystemSoundID(soundUrl, &soundId)
            AudioServicesPlaySystemSound(soundId)
        }
    }
    
    let queue = DispatchQueue(label:"frame",qos: .background)
    // MARK: - ARSessionDelegate
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if recordingFlag {
            let current = Date()
            let diff = current.timeIntervalSince(recordTime)
            if diff * 100 < 100{
                return
            }
            recordTime = current
            self.beep()
            let jsonNode = self.currentFrameInfoToDic(currentFrame: frame)
            queue.async {
                let recordStartTime = getCurrentTime()
                var jsonObject = [String:FrameInfo]()

                jsonObject[jsonNode.imageName] = jsonNode
                let jpgImage = pixelBufferToUIImage(pixelBuffer: frame.capturedImage).jpegData(compressionQuality: 1.0)
                let path = getFilePath(fileFolder: recordStartTime, fileName: jsonNode.imageName)
                try? jpgImage?.write(to: URL(fileURLWithPath:path ))

                if let depth = frame.capturedDepthData{
                    let depthImage = pixelBufferToUIImage(pixelBuffer: depth.depthDataMap).pngData()
                    try? depthImage?.write(to: URL(fileURLWithPath:path+".depth.png"))
                }
                
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
