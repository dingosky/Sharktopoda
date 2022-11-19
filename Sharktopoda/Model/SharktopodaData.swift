//
//  SharktopodaData.swift
//  Created for Sharktopoda on 9/13/22.
//
//  Apache License 2.0 — See project LICENSE file
//

import Foundation
import AppKit
import SwiftUI

final class SharktopodaData: ObservableObject {
  @Published var udpServer: UDPServer = UDP.server
  @Published var udpServerError: String? = nil
  @Published var udpClient: UDPClient?

  /// Open video windows
  @Published var videoWindows = [String: VideoWindow]()
  
  /// Tmp video assets used during Control Open
  @Published var tmpVideoAssets = [String: VideoAsset]()

  init() {
    // Needed for non-View related changes to sharktopodaData to notify observing Views
    UDP.sharktopodaData = self
  }
  
  func latestVideoWindow() -> VideoWindow? {
    guard !videoWindows.isEmpty else { return nil }

    let windows: [VideoWindow] = Array(videoWindows.values)

    if let videoWindow = windows.first(where: \.keyInfo.isKey) {
      return videoWindow
    }

    return windows.sorted(by: { $0 < $1 }).last
  }
}
