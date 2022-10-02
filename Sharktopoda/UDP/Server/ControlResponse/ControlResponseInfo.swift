//
//  ControlResponseInfo.swift
//  Created for Sharktopoda on 9/30/22.
//
//  Apache License 2.0 — See project LICENSE file
//

import Foundation

struct ControlResponseInfo: ControlResponse {
  struct VideoInfo: Codable {
    var uuid: String
    var url: String
    var durationInt: Int
    var frameRate: Float
    var isKey: Bool
    
    init(using videoWindow: VideoWindow) {
      let videoAsset = videoWindow.videoView.videoAsset
      self.uuid = videoAsset.uuid
      self.url = videoAsset.url.absoluteString
      self.durationInt = videoAsset.durationMillis
      self.frameRate = round(videoAsset.frameRate * 100) / 100.0
      self.isKey = videoWindow.keyInfo.isKey
    }
  }
  
  var response: ControlCommand
  var status: ControlResponseStatus

  var uuid: String?
  var url: String?
  var durationInt: Int?
  var frameRate: Float?
  var isKey: Bool?
  
  init(using windowInfo: VideoInfo) {
    response = .info
    status = .ok
    self.uuid = windowInfo.uuid
    self.url = windowInfo.url
    self.durationInt = windowInfo.durationInt
    self.frameRate = windowInfo.frameRate
    self.isKey = windowInfo.isKey
  }

  init(using videoWindow: VideoWindow) {
    let windowInfo = VideoInfo(using: videoWindow)
    self.init(using: windowInfo)
  }
}
