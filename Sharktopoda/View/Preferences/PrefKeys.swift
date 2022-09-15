//
//  PrefKeys.swift
//  Created for Sharktopoda on 9/15/22.
//
//  Apache License 2.0 — See project LICENSE file
//

import Foundation

struct PrefKeys {
  private static var sharktopoda = "Sharktopoda"
  
  private static var network = "\(PrefKeys.sharktopoda).network"
  static var port = "\(PrefKeys.network).port"
  static var timeout = "\(PrefKeys.network).timeout"
    
  private static var annotation = "\(PrefKeys.sharktopoda).annotation"
  
  private static var creation = "\(PrefKeys.annotation).creation"

  private static var creationCursor = "\(PrefKeys.creation).cursor"
  static var creationCursorSize = "\(PrefKeys.creationCursor).size"
  static var creationCursorColor = "\(PrefKeys.creationCursor).color"

  private static var creationBorder = "\(PrefKeys.creation).border"
  static var creationBorderSize = "\(PrefKeys.creationBorder).size"
  static var creationBorderColor = "\(PrefKeys.creationBorder).color"

}
