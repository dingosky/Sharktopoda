//
//  ControlPlay.swift
//  Created for Sharktopoda on 9/20/22.
//
//  Apache License 2.0 — See project LICENSE file
//

import Foundation

struct ControlPlay: ControlMessage {
  var command: ControlCommand
  let uuid: String
  @Default<Double.PlaybackRate> var rate: Double

  var description: String {
    command.rawValue
  }

  func process() -> Data {
    print("CxInc handle: \(self)")
    return ControlResponse.ok(command)
  }
}
