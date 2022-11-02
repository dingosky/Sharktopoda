//
//  SharktopodaCommands.swift
//  Created for Sharktopoda on 9/17/22.
//
//  Apache License 2.0 — See project LICENSE file
//

import SwiftUI

struct SharktopodaCommands: Commands {
  var body: some Commands {
    CommandGroup(after: CommandGroupPlacement.newItem) {
      Divider()

      OpenFileView()
        .keyboardShortcut("O", modifiers: [.command])

      OpenUrlView()
        .keyboardShortcut("O", modifiers: [.shift, .command])
    }
    
    CommandMenu("Video") {
      Button("Play") {
        videoWindow?.play()
      }
      .disabled(videoWindow == nil)
//      .disabled(videoWindow == nil && playerView?.playDirection == .paused)

      Button("Pause") {
        videoWindow?.pause()
      }
      .disabled(videoWindow == nil)
//      .disabled(videoWindow == nil && playerView?.playDirection != .paused)

    }
  }
  
  var videoWindow: VideoWindow? {
    get {
      UDP.sharktopodaData.latestVideoWindow()
    }
  }

  var playerView: NSPlayerView? {
    get {
      videoWindow?.playerView
    }
  }
}
