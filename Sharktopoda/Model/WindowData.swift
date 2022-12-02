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
  
  var _frameDuration: CMTime?
  var _fullSize: CGSize?
  var _localizations: Localizations?
  var _player: AVPlayer?
  var _playerView: PlayerView?
  var _sliderView: NSTimeSliderView?
  var _videoAsset: VideoAsset?
  var _videoControl: VideoControl?
  
  @Published var playerTime: Int = 0
  @Published var playerDirection: PlayerDirection = .paused

  var id: String {
    get { _id! }
    set { _id = newValue }
  }
  
  var frameDuration: CMTime {
    get { _frameDuration! }
    set { _frameDuration = newValue }
  }
  
  var fullSize: CGSize {
    get { _fullSize! }
    set { _fullSize = newValue }
  }
  
  var localizations: Localizations {
    get { _localizations! }
    set { _localizations = newValue }
  }
  
  var player: AVPlayer {
    get { _player! }
    set { _player = newValue }
  }
  
  var playerView: PlayerView {
    get { _playerView! }
    set { _playerView = newValue }
  }
  
  var sliderView: NSTimeSliderView {
    get { _sliderView! }
    set { _sliderView = newValue }
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
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }

      self.pause(false)
      self.step(steps)
    }
  }
  
  var currentFrameTime: Int {
    localizations.frameTime(elapsedTime: videoControl.currentTime)
  }

  func pause(_ withDisplay: Bool = true) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      self.play(rate: 0.0)
      self.playerView.clear()
      self.localizations.clearSelected()

      if withDisplay {
        self.playerView.display(localizations: self.pausedLocalizations())
      }
    }
  }
  
  func play() {
    play(rate: videoControl.previousRate)
  }
  
  func play(rate: Float) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      self.localizations.clearSelected()
      self.playerDirection = PlayerDirection.at(rate: rate)
      self.playerView.clear(localizations: self.pausedLocalizations())
      self.videoControl.play(rate: rate)
    }
  }
  
  var previousDirection: PlayerDirection {
    PlayerDirection.at(rate: videoControl.previousRate)
  }
  
  func reverse() {
    play(rate: -1 * videoControl.previousRate)
  }
  
  func seek(elapsedTime: Int) {
    let frameTime = localizations.frameTime(elapsedTime: elapsedTime)
    videoControl.seek(elapsedTime: frameTime) { [weak self] done in
      let pausedLocalizations = self?.pausedLocalizations() ?? []
      DispatchQueue.main.async {
        self?.playerView.display(localizations: pausedLocalizations)
      }
    }
  }
  
  func step(_ steps: Int) {
    let stepTime = currentFrameTime + steps * localizations.frameDuration
    seek(elapsedTime: stepTime)
  }
  
  var showLocalizations: Bool {
    UserDefaults.standard.bool(forKey: PrefKeys.showAnnotations)
  }
}

extension WindowData {
  func add(localizations controlLocalizations: [ControlLocalization]) {
    let currentFrameNumber = localizations.frameNumber(elapsedTime: videoControl.currentTime)

    controlLocalizations
      .map { Localization(from: $0, size: fullSize) }
      .forEach {
        $0.resize(for: playerView.videoRect)
        localizations.add($0)
        
        guard videoControl.paused else { return }
        guard localizations.frameNumber(for: $0) == currentFrameNumber else { return }
        
        playerView.display(localization: $0)
      }
  }

  func pausedLocalizations() -> [Localization] {
    guard videoControl.paused else { return [] }
    return localizations.fetch(.paused, at: videoControl.currentTime)
  }
}

extension WindowData {
  enum PlayerDirection: Int {
    case reverse = -1
    case paused = 0
    case forward =  1
    
    static func at(rate: Float) -> PlayerDirection {
      if rate == 0.0 {
        return .paused
      } else if 0 < rate {
        return .forward
      } else {
        return .reverse
      }
    }
    
    func opposite() -> PlayerDirection {
      if self == .paused {
        return .paused
      } else {
        return self == .reverse ? .forward : .reverse
      }
    }
  }
}
