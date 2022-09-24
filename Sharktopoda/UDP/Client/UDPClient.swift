//
//  UDPIncoming.swift
//  Created for Sharktopoda on 9/18/22.
//
//  Apache License 2.0 — See project LICENSE file
//
import Foundation
import Network

class UDPClient: ObservableObject {
  struct ClientData {
    let host: String
    let port: Int
    var active: Bool = false
    var error: String? = nil
    
    var endpoint: String {
      "\(host):\(port)"
    }
  }
  
  typealias UDPClientCompletion = (UDPClient) -> Void
  
  private static let queue = DispatchQueue(label: "Sharktopoda UDP Client Queue")
  
  var connection: NWConnection?
  
  var clientData: ClientData
  var completion: UDPClientCompletion?
  var timeout: TimeInterval
  
  static func clientTimeout() -> TimeInterval {
    let prefSetting: Int = UserDefaults.standard.integer(forKey: PrefKeys.timeout)
    let prefMillis = prefSetting == 0 ? 1000 : prefSetting
    return TimeInterval(prefMillis) / 1000.0
  }
  
  static func connect(using connectCommand: ControlConnect, completion: @escaping UDPClientCompletion) {
    let udpClient = UDPClient(using: connectCommand)
    udpClient.completion = completion
    udpClient.connection?.start(queue: UDPClient.queue)
  }
  
  init() {
    clientData = ClientData(host: "", port: 0)
    self.timeout = UDPClient.clientTimeout()
  }
  
  private
  init(using connectCommand: ControlConnect) {
    let host = connectCommand.host
    let port = connectCommand.port
    clientData = ClientData(host: host, port: port)
    
    self.timeout = UDPClient.clientTimeout()
    
    let endpointHost = NWEndpoint.Host(host)
    let endpointPort = NWEndpoint.Port(rawValue: UInt16(port))!
    let endpoint = NWEndpoint.hostPort(host: endpointHost, port: endpointPort)
    
    let connection = NWConnection(to: endpoint, using: .udp)
    connection.stateUpdateHandler = self.stateUpdate(to:)
    
    self.connection = connection
    
    log("connecting to \(clientData.endpoint)")
  }
  
  func stateUpdate(to update: NWConnection.State) {
    switch update {
      case .preparing, .setup, .waiting:
        return
      case .ready:
        log("state \(update)")
        verifyConnection()
      case .failed(let error):
        udpError(error: error)
        log("failed with error \(error)")
        completion?(self)
      case .cancelled:
        udpActive(active: false)
        log("state \(update)")
        completion?(self)
      @unknown default:
        log("state unknown")
    }
  }
  
  func verifyConnection() {
    process(ClientPing())
  }
  
  func process(_ message: ClientMessage) {
    let data = message.data()
    
    var receivedReply = false
    
    UDPClient.queue.asyncAfter(deadline: .now() + timeout) { [weak self] in
      guard receivedReply == false else { return }
      if let completion = self?.completion {
        completion(self!)
      }
    }

    if let connection = self.connection {
      connection.send(content: data, completion: .contentProcessed({ _ in }))

      connection.receiveMessage(completion: { [weak self] data, _, isComplete, error in
        receivedReply = true
        
        if let error = error {
          self?.udpError(error: error)
          self?.log("ping error: \(error)")
        } else {
          self?.udpActive(active: true)
        }
        if let completion = self?.completion {
          completion(self!)
        }
      })
    }
  }
  
  func send(_ message: ClientMessage, completion: NWConnection.SendCompletion) {
    guard clientData.active else {
      log("client connection not active ")
      return
    }
    
    log("send \(message.command)")
    
    let data = message.data()
    connection?.send(content: data, completion: completion)
  }
  
  func receive() {
    
  }
  
  //  func timeout(for message: ClientMessage, on connection: NWConnection) {
  //    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
  //      self.heyNow()
  //    }
  //
  //  }
  
  func udpActive(active: Bool) {
    let host = clientData.host
    let port = clientData.port
    clientData = ClientData(host: host, port: port, active: active)
    
    let activeState = (clientData.active ? "" : "in") + "active"
    log("\(clientData.endpoint) \(activeState)")
  }
  
  func udpError(message: String) {
    let host = clientData.host
    let port = clientData.port
    clientData = ClientData(host: host, port: port, error: message)
  }
  
  func udpError(error: Error) {
    udpError(message: error.localizedDescription)
  }
  
  func stop()  {
    if let connection = connection {
      connection.stateUpdateHandler = nil
      connection.cancel()
      
      let endpoint = clientData.endpoint
      clientData = ClientData(host: "", port: 0)
      
      log("stopped \(endpoint)")
    }
  }
  
  func log(_ msg: String) {
    let logHdr = "Sharktopoda UDP Client"
    UDP.log(hdr: logHdr, msg)
  }
}
