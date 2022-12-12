//
//  ControlUpdateLocalizations.swift
//  Created for Sharktopoda on 10/8/22.
//
//  Apache License 2.0 — See project LICENSE file
//

import Foundation

struct ControlUpdateLocalizations: ControlMessage {
  var command: ControlCommand
  var uuid: String
  var localizations: [ControlLocalization]
  
  func process() -> ControlResponse {
    withWindowData(id: uuid) { windowData in
      localizations
        .forEach { controlLocalization in
          windowData.localizationData.update(using: controlLocalization)
        }
      return ok()
    }
  }
}
