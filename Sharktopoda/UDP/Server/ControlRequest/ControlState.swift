//
//  ControlStatus.swift
//  Created for Sharktopoda on 9/21/22.
//
//  Apache License 2.0 — See project LICENSE file
//

import Foundation

struct ControlState: ControlMessage {
  var command: ControlCommand
  var uuid: String
  
  func process() -> ControlResponse {
    withWindowData(id: uuid) { windowData in
      ControlResponseState(using: windowData)
    }
  }
}
