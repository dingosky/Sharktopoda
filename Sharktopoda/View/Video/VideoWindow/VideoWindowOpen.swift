//
//  VideoWindowOpen.swift
//  Created for Sharktopoda on 11/22/22.
//
//  Apache License 2.0 — See project LICENSE file
//

import Foundation

extension VideoWindow {
  static func onMain(_ fn: @escaping () -> Void) {
    DispatchQueue.main.async { fn() }
  }
  
  static func open(url: URL) {
    open(id: url.path, url: url, alert: true)
  }
  
  static func open(id: String, url: URL, alert: Bool = false) {
    if let videoWindow = UDP.sharktopodaData.videoWindows[id] {
      onMain {
        videoWindow.bringToFront()
      }
    } else {
      Task {
        if let videoAsset = await VideoAsset(id: id, url: url) {
          window(for: videoAsset, alert: alert)
          
          if let client = UDP.sharktopodaData.udpClient {
            let openDoneMessage = ClientMessageOpenDone(uuid: id)
            client.process(openDoneMessage)
          }
        } else {
          report(path: url.absoluteString,
                 error: OpenVideoError.notLoaded(url),
                 alert: alert)
        }
      }
    }
  }
  
  private static func window(for videoAsset: VideoAsset, alert: Bool) {
    if !videoAsset.isPlayable {
      report(path: videoAsset.url.absoluteString,
             error: OpenVideoError.notPlayable(videoAsset.url),
             alert: alert)
    } else {
      let videoWindow = VideoWindow(for: videoAsset, with: UDP.sharktopodaData)
      UDP.sharktopodaData.videoWindows[videoAsset.id] = videoWindow
      onMain {
        videoWindow.windowData.sliderView.setupControlViewAnimation()
        videoWindow.bringToFront()
      }
    }
  }
  
  private static func report(path: String, error: OpenVideoError, alert: Bool) {
    if alert {
      let openAlert = OpenAlert(path: path, error: error)
      onMain { openAlert.show() }
    }
    UDP.log(error.description)
  }
}
