//
//  WindowData.swift
//  Created for Sharktopoda on 11/25/22.
//
//  Apache License 2.0 — See project LICENSE file
//

import AVKit

final class WindowData: Identifiable, ObservableObject {
  var _id: String?
  
  var windowKeyInfo: WindowKeyInfo = WindowKeyInfo()
  
  var _frameRate: Float?
  var _fullSize: CGSize?
  var _localizationData: LocalizationData?
  var _player: AVPlayer?
  var _playerView: PlayerView?
  var _timeSlider: NSTimeSlider?
  var _videoAsset: VideoAsset?
  var _videoControl: VideoControl?
  
  @Published var playerTime: Int = 0
  @Published var playerDirection: PlayerDirection = .paused
  @Published var playerVolumeLevel: Float = 1.0 {
    didSet {
      player.volume = playerVolumeLevel
    }
  }
  @Published var playerVolumeMute: Bool = false {
    didSet {
      player.volume = playerVolumeMute ? 0.0 : playerVolumeLevel
    }
  }
  @Published var showLocalizations: Bool = UserDefaults.standard.bool(forKey: PrefKeys.showAnnotations)
  
  var id: String {
    get { _id! }
    set { _id = newValue }
  }
  
  var localizationData: LocalizationData {
    get { _localizationData! }
    set { _localizationData = newValue }
  }
  
  var player: AVPlayer {
    get { _player! }
    set { _player = newValue }
  }
  
  var playerView: PlayerView {
    get { _playerView! }
    set { _playerView = newValue }
  }
  
  var timeSlider: NSTimeSlider {
    get { _timeSlider! }
    set { _timeSlider = newValue }
  }
  
  var videoAsset: VideoAsset {
    get { _videoAsset! }
    set { _videoAsset = newValue }
  }

  var videoControl: VideoControl {
    get { _videoControl! }
    set { _videoControl = newValue }
  }
}

extension WindowData {
  func advance(steps: Int) {
    step(steps)
  }
  
  func pause(_ withDisplay: Bool = true) {
    guard !videoControl.paused else { return }

    play(rate: 0.0)
    displaySpanned()

//    let currentTime = videoControl.currentTime
//    videoControl.frameSeek(to: currentTime) { [weak self] done in
//      if withDisplay {
//        self?.displaySpanned()
//      }
//    }
  }
  
  func play(rate: Float) {
    playerDirection = PlayerDirection.at(rate: rate)
    videoControl.play(rate: rate)

    localizationData.clearSelected()
    playerView.clear()
  }
  
  func playBackward() {
    play(rate: -1 * videoControl.previousSpeed)
  }
  
  func playForward() {
    play(rate: videoControl.previousSpeed)
  }
  
  func playerResume(_ direction: WindowData.PlayerDirection) {
    if direction == .paused {
       displaySpanned()
    } else {
      play(rate: videoControl.previousDirection.rawValue * videoControl.previousSpeed)
    }
  }

  func seek(elapsedTime: Int) {
    if !videoControl.paused {
      play(rate: 0.0)
    }
    videoControl.frameSeek(to: elapsedTime)
  }

  func seek(time: CMTime) {
    if !videoControl.paused {
      play(rate: 0.0)
    }
    videoControl.frameSeek(to: time)
  }
  
  func step(_ steps: Int) {
    let delta = Int(round(Float(steps) * videoAsset.frameMillis))
    seek(time: videoControl.currentTime + CMTime.from(delta, in: .millis))
  }
}

extension WindowData {
  func add(localizations controlLocalizations: [ControlLocalization]) {
    let currentFrameNumber = localizationData.frameNumber(of: videoControl.currentTime.asMillis)

    let frameLocalizations = controlLocalizations
      .map { Localization(from: $0, size: videoAsset.fullSize) }
      .reduce(into: [Localization]()) { acc, localization in
        localization.resize(for: playerView.videoRect)
        localizationData.add(localization)
        if localizationData.frameNumber(for: localization) == currentFrameNumber {
          acc.append(localization)
        }
      }

    guard videoControl.paused else { return }
    guard showLocalizations else { return }

    playerView.display(localizations: frameLocalizations)
  }
  
  func pausedLocalizations() -> [Localization] {
    localizationData.fetch(.paused, at: videoControl.currentTime.asMillis)
  }

  func displaySpanned(force: Bool = true) {
    guard force || showLocalizations else { return }
    playerView.display(localizations: spannedLocalizations())
  }

  /// Spanned localizations are all localizations that would be displayed at the current time during playback
  func spannedLocalizations() -> [Localization] {
    /// If using localization duration, we currently beg out of attempting to find all "spanned" localizations
    if localizationData.useDuration {
      return pausedLocalizations()
    }

    return localizationData.fetch(spanning: videoControl.currentTime.asMillis)
  }
}

extension WindowData {
  enum PlayerDirection: Float {
    case backward = -1.0
    case paused = 0.0
    case forward =  1.0
    
    static func at(rate: Float) -> PlayerDirection {
      if rate == 0.0 {
        return .paused
      } else if 0 < rate {
        return .forward
      } else {
        return .backward
      }
    }
    
    func opposite() -> PlayerDirection {
      if self == .paused {
        return .paused
      } else {
        return self == .backward ? .forward : .backward
      }
    }
  }
}
