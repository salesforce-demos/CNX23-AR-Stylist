//
//  ViewController.swift
//  ar-stylist
//
//  Created by Joe Andolina on 5/29/23.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    let configuration = ARFaceTrackingConfiguration()
    let meshOpacity: Double = 1.0
    
    @IBOutlet weak var cameraTop: NSLayoutConstraint!
    @IBOutlet weak var playerTop: NSLayoutConstraint!
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var playerView: PlayerView!
    @IBOutlet weak var flashView: UIView!

    var analysis = ""
    var reportChange: (() -> Void)!
    var faceNode: SCNNode!

    //-----------------------------------------------------------------------
    override func viewDidLoad() {
        print("ViewController viewDidLoad")
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.showsStatistics = false
        guard ARFaceTrackingConfiguration.isSupported else {
            print("Face tracking is not supported on this device")
            return
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        self.flashView.addGestureRecognizer(tapGesture)
        self.flashView.isUserInteractionEnabled = true
        self.flashView.layer.backgroundColor = UIColor.white.cgColor
        self.flashView.layer.opacity = 0.011
        
        self.playerTop.constant = 0
        if let url = Bundle.main.url(forResource: "fashion", withExtension: "mp4") {
            self.playerView.load(url: url)
        }
    }
    
    //-----------------------------------------------------------------------
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sceneView.session.run(self.configuration)
        
        if(self.faceNode != nil){
            self.faceNode.geometry?.firstMaterial?.transparency = self.meshOpacity
            self.faceNode.geometry?.firstMaterial?.emission.intensity = 1.0
        }
    }
    
    //-----------------------------------------------------------------------
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
        
    //-----------------------------------------------------------------------
    @objc func viewTapped(_ sender: UITapGestureRecognizer) {
        print("Tap")
        DispatchQueue.main.async {
            if(self.cameraTop.constant == 0){
                self.animateSave()
            }
            else {
                self.showCamera()
            }
        }
    }
    
    //-----------------------------------------------------------------------
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let faceMesh = ARSCNFaceGeometry(device: sceneView.device!)
        let node = SCNNode(geometry: faceMesh)
        
        node.geometry?.firstMaterial?.fillMode = .fill
        node.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "faceOverlay")
        node.geometry?.firstMaterial?.transparency = self.meshOpacity
        
        node.geometry?.firstMaterial?.emission.contents = UIColor.green
        node.geometry?.firstMaterial?.emission.intensity = 0
        
        self.faceNode = node;
        return node
    }
    
    //-----------------------------------------------------------------------
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if let faceAnchor = anchor as? ARFaceAnchor, let faceGeometry = node.geometry as? ARSCNFaceGeometry {
            faceGeometry.update(from: faceAnchor.geometry)
            expression(anchor: faceAnchor)
            
            DispatchQueue.main.async {
                self.reportChange()
            }
        }
    }
    
    //-----------------------------------------------------------------------
    func animateSave(){
        let intensity = CABasicAnimation(keyPath: "emission.intensity")
        let transparency = CABasicAnimation(keyPath: "transparency")
        intensity.fromValue = 0.0
        intensity.toValue = 1.0
        intensity.duration = 1.0
        intensity.fillMode = .forwards
        intensity.isRemovedOnCompletion = false

        transparency.fromValue = self.meshOpacity
        transparency.toValue = 1.0
        transparency.duration = 1.0
        transparency.fillMode = .forwards
        transparency.isRemovedOnCompletion = false

        let group = CAAnimationGroup()
        group.animations = [intensity, transparency]
        group.duration = 1.0
        
        UIView.animate(withDuration: 0.2, delay: 0.5, options: []) {
            self.flashView.layer.opacity = 1.0
        } completion: { success in
            self.flashView.layer.opacity = 0.011
            self.faceNode.geometry?.firstMaterial?.transparency = 1.0
            self.faceNode.geometry?.firstMaterial?.emission.intensity = 1.0
            self.sceneView.session.pause()
            self.hideCamera()
        }
    }
    
    //-----------------------------------------------------------------------
    func hideCamera(){
        self.cameraTop.constant = 800 // Whatever the new constant should be
        UIView.animate(withDuration: 0.75, delay: 1.0, options: .curveEaseIn, animations: {
            self.sceneView.alpha = 0.5
            self.view.layoutIfNeeded() // This causes the view to have its layout updated immediately
        }) { success in
            self.playerView.play()
        }
    }
    
    //-----------------------------------------------------------------------
    func showCamera(){
        self.cameraTop.constant = 0 // Whatever the new constant should be
        self.sceneView.alpha = 1
        sceneView.session.run(self.configuration)
        self.faceNode.geometry?.firstMaterial?.transparency = meshOpacity
        self.faceNode.geometry?.firstMaterial?.emission.intensity = 0.0
        self.view.layoutIfNeeded()
        self.playerView.stop()
    }
    
    //-----------------------------------------------------------------------
    func expression(anchor: ARFaceAnchor) {
        let smileLeft = anchor.blendShapes[.mouthSmileLeft]
        let smileRight = anchor.blendShapes[.mouthSmileRight]
        let cheekPuff = anchor.blendShapes[.cheekPuff]
        let tongue = anchor.blendShapes[.tongueOut]
        self.analysis = ""
        
        if ((smileLeft?.decimalValue ?? 0.0) + (smileRight?.decimalValue ?? 0.0)) > 0.9 {
            self.analysis += "You are smiling. "
        }
        
        if cheekPuff?.decimalValue ?? 0.0 > 0.1 {
            self.analysis += "Your cheeks are puffed. "
        }
        
        if tongue?.decimalValue ?? 0.0 > 0.1 {
            self.analysis += "Don't stick your tongue out! "
        }
    }
}
