//
//  CMTime.swift
//  Created for Sharktopoda on 10/3/22.
//
//  Apache License 2.0 — See project LICENSE file
//

import AVFoundation

extension CMTime {
  static let valueMillis: Int32 = 1_000
  static let valueMicros: Int32 = 1_000_000

  enum Timescale: Int32 {
    case millis = 1_000
    case micros = 1_000_000
  }
  
  func to(_ timescale: Timescale) -> Int {
    return Int(seconds * Double(timescale.rawValue))
  }
  
  static func from(_ time: Double, in timescale: Timescale) -> CMTime {
    guard !time.isNaN,
          !time.isInfinite else { return .zero }

    return from(Int(time), in: timescale)
  }
  
  static func from(_ time: Int, in timescale: Timescale) -> CMTime {
    CMTimeMake(value: Int64(time), timescale: timescale.rawValue)
  }

  var asMillis: Int {
    to(.millis)
  }
  
  var asMicros: Int {
    to(.micros)
  }

}
