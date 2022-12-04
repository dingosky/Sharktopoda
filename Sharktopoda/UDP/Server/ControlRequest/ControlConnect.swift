//
//  ControlConnect.swift
//  Created for Sharktopoda on 9/19/22.
//
//  Apache License 2.0 — See project LICENSE file
//

import Foundation
import Network

struct ControlConnect: ControlMessage {
  var command: ControlCommand
  @Default<String.Localhost> var host: String
  let port: Int
  
  var endpoint: String {
    "\(host):\(port)"
  }
  
  func process() -> ControlResponse {
    UDPClient.connect(using: self) { client in
      DispatchQueue.main.async {
        UDP.sharktopodaData.udpClient = client
      }
    }

    return ControlResponseOk(response: command)
  }
}
