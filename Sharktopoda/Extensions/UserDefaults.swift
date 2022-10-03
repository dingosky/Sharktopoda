//
//  UserDefaults.swift
//  Created for Sharktopoda on 10/3/22.
//
//  Apache License 2.0 — See project LICENSE file
//

import SwiftUI

extension UserDefaults {
  func setColor(_ color: Color, forKey key: String) {
    set(color.toHex(), forKey: key)
  }
  
  func color(forKey key: String) -> Color {
    guard let hex = object(forKey: key) as? String else { return .black }
    guard let color = Color(hex: hex) else { return .red }
    return color
  }
}
