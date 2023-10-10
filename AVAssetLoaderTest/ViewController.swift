//
//  ViewController.swift
//  AVAssetLoaderSample
//
//  Created by Silviu Pop on 10/10/23.
//

import UIKit
import AVKit

class ViewController: UIViewController {

    let delegate = ResourceLoaderDelegate()

    @IBAction func didTapStartVideo(_ sender: Any) {
        
        let streamingAsset = AVURLAsset(url: URL(string: "customProtocol://something.com/file.mp4")!)
        streamingAsset.resourceLoader.setDelegate(delegate, queue: delegate.queue)
        let playerItem = AVPlayerItem(asset: streamingAsset)
        
        let playerVC = AVPlayerViewController()
        playerVC.player = AVPlayer(playerItem: playerItem)
        playerVC.player?.play()
        
        playerVC.allowsVideoFrameAnalysis = false
         
        self.present(playerVC, animated: true)
    }

}

