//
//  VideoControl.swift
//  Created for Sharktopoda on 11/19/22.
//
//  Apache License 2.0 — See project LICENSE file
//

import AVFoundation
import Foundation

final class VideoControl {
  private var windowData: WindowData

  let quickTolerance: CMTime
  let seekTolerance: CMTime

  var previousDirection: WindowData.PlayerDirection = .paused
  var previousSpeed: Float = 1.0
  
  init (windowData: WindowData) {
    self.windowData = windowData

    let quickMillis = min(windowData.videoAsset.duration.asMillis / 500, 500)
    quickTolerance = CMTime.from(quickMillis, in: .millis)
    let frameDurationTime = CMTime.from(windowData.videoAsset.frameMillis, in: .millis)
    seekTolerance = CMTimeMultiplyByFloat64(frameDurationTime, multiplier: 0.25)
  }
  
  func canStep(_ steps: Int) -> Bool {
    guard let item = currentItem else { return false }
    return steps < 0 ? item.canStepBackward : item.canStepForward
  }

  var currentItem: AVPlayerItem? {
    player.currentItem
  }
  
  var currentTime: CMTime {
    player.currentItem?.currentTime() ?? CMTime.invalid
  }

  func pause() {
    guard player.rate != 0 else { return }
    player.rate = 0.0
  }
  
  var paused: Bool {
    rate == 0.0
  }

  func play() {
    play(rate: previousSpeed)
  }
  
  func play(rate: Float) {
    guard rate != 0.0 else { return pause() }
    
    previousSpeed = abs(rate)
    previousDirection = 0 < rate ? .forward : .backward
    player.rate = rate
  }
  
  private var player: AVPlayer {
    windowData.player
  }
  
  var rate: Float {
    get { player.rate }
  }
  
  func reverse() {
    play(rate: -1 * previousSpeed)
  }
  
  func quickSeek(to time: CMTime) {
    player.seek(to: time,
                toleranceBefore: quickTolerance,
                toleranceAfter: quickTolerance)
  }
  
  func frameSeek(to time: CMTime) {
    player.seek(to: time,
                toleranceBefore: seekTolerance,
                toleranceAfter: seekTolerance)
  }

  func frameSeek(to elapsedTime: Int) {
    frameSeek(to: CMTime.from(elapsedTime, in: .millis))
  }
  
  func frameSeek(to time: CMTime, done: @escaping (Bool) -> Void) {
    player.seek(to: time,
                toleranceBefore: seekTolerance,
                toleranceAfter: seekTolerance,
                completionHandler: done)
  }
  
  func frameSeek(to elapsedTime: Int, done: @escaping (Bool) -> Void) {
    frameSeek(to: CMTime.from(elapsedTime, in: .millis), done: done)
  }
}
