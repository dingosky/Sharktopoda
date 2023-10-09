//
//  VideoAsset.swift
//  Created for Sharktopoda on 9/15/22.
//
//  Apache License 2.0 — See project LICENSE file
//

import AVFoundation

// CxNote Binds to first AVAsset video track

final class VideoAsset {
  
  let id: String
  let url: URL
  
  var avAsset: AVURLAsset

  var duration: CMTime
  var frameRate: Float
  var frameMillis: Float
  var fullSize: NSSize
  init(id: String, url: URL) async throws {
    self.id = id
    self.url = url

    
    do {
      avAsset = AVURLAsset(url: url)
      
      let videoTracks = try await avAsset.loadTracks(withMediaType: .video)
      guard let videoTrack = videoTracks.first else {
        throw OpenVideoError.noVideo(url)
      }
      
      guard try await videoTrack.load(.isPlayable) else {
        throw OpenVideoError.notPlayable(url)
      }

      duration = try await avAsset.load(.duration)

      frameRate = try await videoTrack.load(.nominalFrameRate)
      frameMillis = 1000.0 / frameRate

      let (videoPreferredTransform, videoNaturalSize) =
        try await videoTrack.load(.preferredTransform, .naturalSize)

      let size = videoNaturalSize.applying(videoPreferredTransform)
      fullSize = NSMakeSize(abs(size.width), abs(size.height))
    } catch let error {
      throw OpenVideoError.loadProperty(url, error: error)
    }
  }
  
  func frameGrab(millis captureMillis: Int, destination: String) async -> FrameGrabResult {
    let imageGenerator = AVAssetImageGenerator(asset: avAsset)
    imageGenerator.requestedTimeToleranceAfter = CMTime.zero
    imageGenerator.requestedTimeToleranceBefore = CMTime.zero

    do {
      let (cgImage, _) = try await imageGenerator.image(at: CMTime.from(captureMillis, in: .millis))
      if let error = cgImage.pngWrite(to: destination) {
        return .failure(error)
      } else {
        return .success(captureMillis)
      }
    } catch(let error) {
      return .failure(error)
    }
  }
}
