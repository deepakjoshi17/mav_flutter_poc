//
//  SampleHandler.swift
//  MavScreenshareBroadcast
//
//  Created by Yogesh Markandey on 18/06/25.
//

import ReplayKit
import os

let logger = Logger(subsystem: "com.example.mavflutter.mavFlutter.MavScreenshareBroadcast", category: "SampleHandler")


class SampleHandler: RPBroadcastSampleHandler {

    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        // User has requested to start the broadcast. Setup info from the UI extension can be supplied but optional.
        logger.info("✅ Broadcast started")
    }
    
    override func broadcastPaused() {
        // User has requested to pause the broadcast. Samples will stop being delivered.
        logger.info("⚠️ Broadcast paused")
    }
    
    override func broadcastResumed() {
        // User has requested to resume the broadcast. Samples delivery will resume.
        logger.info("⚠️ Broadcast resumed")
    }
    
    override func broadcastFinished() {
        // User has requested to finish the broadcast.
        logger.info("✅ Broadcast finished")
    }
    
    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        logger.info("ℹ️ Video sample received")
        switch sampleBufferType {
        case RPSampleBufferType.video:
            // Handle video sample buffer
            break
        case RPSampleBufferType.audioApp:
            // Handle audio sample buffer for app audio
            break
        case RPSampleBufferType.audioMic:
            // Handle audio sample buffer for mic audio
            break
        @unknown default:
            // Handle other sample buffer types
            fatalError("Unknown type of sample buffer")
        }
    }
}
