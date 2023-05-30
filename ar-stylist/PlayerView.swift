//
//  PlayerView.swift
//  ar-stylist
//
//  Created by Joe Andolina on 5/29/23.
//
import UIKit
import AVFoundation

class PlayerView: UIView {
    var player: AVPlayer? {
        get {
            return playerLayer.player
        }
        set {
            playerLayer.player = newValue
        }
    }

    var playerLayer: AVPlayerLayer {
        let vLayer = layer as! AVPlayerLayer
        vLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        return vLayer
    }

    // Override UIView property
    override static var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    func load(url: URL){
        self.player = AVPlayer(url: url)
    }
    
    func play(){
        self.player?.play()
    }
    
    func pause(){
        self.player?.pause()
    }
    
    func rewind(){
        self.player?.seek(to: CMTime.zero)
    }
    
    func stop(){
        self.pause()
        self.rewind()
    }
    
//    let videoURL = URL(string: "https://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4")
//    let player = AVPlayer(url: videoURL!)
//    let playerLayer = AVPlayerLayer(player: player)
//    playerLayer.frame = self.view.bounds
//    self.view.layer.addSublayer(playerLayer)
//    player.play()
}
