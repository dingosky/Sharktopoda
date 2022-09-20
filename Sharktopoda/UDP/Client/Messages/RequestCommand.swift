//
//  OutgoingCommand.swift
//  Created for Sharktopoda on 9/19/22.
//
//  Apache License 2.0 — See project LICENSE file
//

import Foundation

enum RequestCommand: String, Codable {
  case captureDone
  case addLocalizations
  case removeLocalizations
  case updateLocalizations
  case clearLocalizations
  case selectLocalizations
  case ping
}
