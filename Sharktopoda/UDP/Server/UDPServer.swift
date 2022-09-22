//
//  UDPServer.swift
//  Created for Sharktopoda on 9/14/22.
//
//  Apache License 2.0 — See project LICENSE file
//

import Foundation
import Network

class UDPServer {
  private static var defaultPort = 8800
  
  var listener: NWListener
  var queue: DispatchQueue
  var port: Int
  
  init() {
    let prefPort: Int = UserDefaults.standard.integer(forKey: PrefKeys.port)
    
    if prefPort == 0 {
      port = UDPServer.defaultPort
      UserDefaults.standard.setValue(port, forKey: PrefKeys.port)
    } else {
      port = prefPort
    }

    queue = DispatchQueue(label: "Sharktopoda UDP Server Queue")
    
    listener = try! NWListener(using: .udp, on: NWEndpoint.Port(rawValue: UInt16(port))!)
    listener.stateUpdateHandler = stateUpdate(to:)
    listener.newConnectionHandler = processConnection(from:)
    
    listener.start(queue: queue)
    
    log("started on port \(port)")
  }
  
  func runningOnPort() -> Int {
    Int(listener.port?.rawValue ?? 0)
  }
  
  func stateUpdate(to update: NWListener.State) {
    switch update {
      case .setup, .waiting:
        return
        
      case .ready, .cancelled:
        log("state \(update)")
        
      case .failed(let error):
        log("failed with error \(error)")
        exit(EXIT_FAILURE)
        
      @unknown default:
        log("state unknown")
    }
  }
  
  private func processConnection(from connection: NWConnection) {
    let udpMessage = UDPMessage(using: connection) { data in
      connection.send(content: data, completion: .contentProcessed({ _ in }))
    }
    udpMessage.start()
  }
  
  func stop() {
    let port = runningOnPort()
    
    listener.stateUpdateHandler = nil
    listener.newConnectionHandler = nil
    listener.cancel()
    
    log("stopped on port \(port)")
  }
  
  func log(_ msg: String) {
    let logHdr = "Sharktopoda UDP Server"
    UDP.log(hdr: "\(logHdr)", msg)
  }
  
}
