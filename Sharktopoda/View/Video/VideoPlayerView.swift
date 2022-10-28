//
//  VideoPlayerView.swift
//  Created for Sharktopoda on 10/12/22.
//
//  Apache License 2.0 — See project LICENSE file
//

import AppKit
import AVFoundation

final class VideoPlayerView: NSView {
  
  private let rootLayer = CALayer()
  private let playerLayer = AVPlayerLayer()

  private var localizations: Localizations?

  private var _videoAsset: VideoAsset?
  
  private var selectedLayer: LocalizationLayer?
  private var selectedLocation: CGRect.Location?
  
  init(videoAsset: VideoAsset) {
    let videoSize = videoAsset.size!
    super.init(frame: NSMakeRect(0, 0, videoSize.width, videoSize.height))

    _videoAsset = videoAsset
    setup()
  }
  
  override public init(frame frameRect: NSRect) {
    super.init(frame: frameRect)

    setup()
  }
  
  required public init?(coder decoder: NSCoder) {
    super.init(coder: decoder)

    setup()
  }
  
  private func setup() {
    wantsLayer = true
    layer = rootLayer
    
    let player = AVPlayer(url: videoAsset.url)
    playerLayer.player = player
    playerLayer.frame = bounds
    playerLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        
    rootLayer.addSublayer(playerLayer)

    localizations = Localizations(playerItem: currentItem!,
                                    frameDuration: videoAsset.frameDuration.asMillis())

    setTimeObserver()
  }
}

/// Enums
extension VideoPlayerView {
  enum PlayDirection: Int {
    case reverse = -1
    case paused = 0
    case forward =  1
    
    func opposite() -> PlayDirection {
      if self == .paused {
        return .paused
      } else {
        return self == .reverse ? .forward : .reverse
      }
    }
  }
}

/// Computed properties
extension VideoPlayerView {
  var currentItem: AVPlayerItem? {
    player?.currentItem
  }
  
  var currentTime: Int {
    get {
      guard let currentTime = currentItem?.currentTime() else { return 0 }
      return currentTime.asMillis()
    }
  }
  
  var displayLocalizations: Bool {
    UserDefaults.standard.bool(forKey: PrefKeys.showAnnotations)
  }

  private var player: AVPlayer? {
    get { playerLayer.player }
  }
  
  var scale: CGFloat {
    /// Player always maintains original aspect so either width or height would do here
    get {
      videoRect.size.width / videoSize.width
    }
  }
  
  var videoAsset: VideoAsset {
    get {
      _videoAsset!
    }
  }
  
  var videoRect: CGRect {
    get {
      playerLayer.videoRect
    }
  }
  
  var videoSize: CGSize {
    get {
      videoAsset.size ?? .zero
    }
  }
}

/// Localizations
extension VideoPlayerView {
  func addLocalization(_ localization: Localization) -> Bool {
    let layer = LocalizationLayer(for: localization,
                                  videoRect: videoRect,
                                  scale: scale)
    
    guard let localizations = localizations,
          localizations.add(layer) else { return false }
    
    guard paused else { return true }
    
    let currentFrameNumber = localizations.frameNumber(elapsedTime: currentTime)
    let localizationFrameNumber = localizations.frameNumber(for: localization)
    
    if displayLocalizations,
      currentFrameNumber == localizationFrameNumber {
      DispatchQueue.main.async { [weak self] in
        self?.playerLayer.addSublayer(layer)
      }
    }

    return true
  }

  func clearLocalizations() {
    guard let localizations = localizations else { return }
    
    clearPause()
    
    localizations.clear()
  }
  
  func removeLocalizations(_ ids: [String]) -> [Bool] {
    guard localizations != nil else {
      return ids.map { _ in false }
    }
    
    let result = ids.map { localizations!.remove(id: $0) }
    
    displayPause()
    
    return result
  }
  
  func selectLocalizations(_ ids: [String]) -> [Bool] {
    guard let localizations = localizations else {
      return ids.map { _ in false }
    }

    localizations.clearSelected()
    
    return ids.map { localizations.select($0) }
  }
  
  func updateLocalization(_ localization: Localization) -> Bool {
    guard localizations != nil else { return false }

    let layer = LocalizationLayer(for: localization,
                                  videoRect: videoRect,
                                  scale: scale)
    
    let result = localizations!.update(layer)
    displayPause()
    return result
  }
}

/// Video
extension VideoPlayerView {
  func canStep(_ steps: Int) -> Bool {
    guard let item = currentItem else { return false }
    return steps < 0 ? item.canStepBackward : item.canStepForward
  }

  var playDirection: PlayDirection {
    if paused {
      return .paused
    } else if 0 < rate {
      return .forward
    } else {
      return .reverse
    }
  }

  func frameGrab(at captureTime: Int, destination: String) async -> FrameGrabResult {
    return await videoAsset.frameGrab(at: captureTime, destination: destination)
  }

  func pause() {
    guard !paused else { return }
    
    player?.pause()
    clearAllLayers()
    displayPause()
  }
  
  var paused: Bool {
    rate == 0.0
  }

  var rate: Float {
    get { player?.rate ?? Float(0) }
    set {
      if paused {
        clearPause()
      }
      if newValue == 0.0 {
        pause()
      } else if 0 < newValue {
        displayLayers(.forward, at: currentTime)
      } else {
        displayLayers(.reverse, at: currentTime)
      }
      player?.rate = newValue
    }
  }

  func seek(elapsed: Int) {
    guard paused else { return }

    clearAllLayers()
    

    
    /// Within a half frame span of the target seek we'll see all the frames for the specified seek time
    let quarterFrame = CMTimeMultiplyByFloat64(videoAsset.frameDuration, multiplier: 0.25)
    player?.seek(to: CMTime.fromMillis(elapsed), toleranceBefore: quarterFrame, toleranceAfter: quarterFrame) { [weak self] done in
      if done,
         UserDefaults.standard.bool(forKey: PrefKeys.showAnnotations) {
        self?.displayPause()
      }
    }
  }

  func step(_ steps: Int) {
    guard paused else { return }
    
    clearAllLayers()
    
    guard displayLocalizations else { return }
    
    currentItem?.step(byCount: steps)
    displayPause()
  }
}

/// Abstract layers
extension VideoPlayerView {
  func localizationLayers() -> [LocalizationLayer] {
    return playerLayer.sublayers?.reduce(into: [LocalizationLayer]()) { acc, layer in
      if let layer = layer as? LocalizationLayer {
        acc.append(layer)
      }
    } ?? []
  }

}

/// Pause layers
extension VideoPlayerView {
  func displayPause() {
    displayLayers(.paused, at: currentTime)
  }
  
  func clearPause() {
    clearAllLayers()
  }
  
  func resized() {
    guard paused else { return }
      
    for layer in localizationLayers() {
      let layerRect = layer.rect(videoRect: videoRect, scale: scale)
      layer.frame = layerRect
      layer.path = CGPath(rect: CGRect(origin: .zero, size: layerRect.size), transform: nil)
    }
  }
}

/// Display and clear layers
extension VideoPlayerView {
  private func displayLayers(_ direction: PlayDirection, at elapsedTime: Int) {
    guard displayLocalizations else { return }
    
    guard let layerIds = localizations?.layerIds(direction, at: elapsedTime) else { return }
    
    layerIds
      .forEach { id in
        guard let layer = localizations?.localizationLayer[id] else { return }
        DispatchQueue.main.async { [weak self] in
          self?.playerLayer.addSublayer(layer)
        }
      }
  }
  
  private func clearLayers(_ direction: PlayDirection, at elapsedTime: Int) {
    guard let layerIds = localizations?.layerIds(direction, at: elapsedTime) else { return }
    
    layerIds
      .forEach { id in
        guard let layer = localizations?.localizationLayer[id] else { return }
        DispatchQueue.main.async {
          layer.removeFromSuperlayer()
        }
      }
  }

  private func clearAllLayers() {
    localizationLayers()
      .forEach { layer in
        DispatchQueue.main.async {
          layer.removeFromSuperlayer()
        }
      }
  }
}

/// Player time callback
extension VideoPlayerView {
  func setTimeObserver() {
    let queue = DispatchQueue(label: "Sharktopoda Video Queue: \(videoAsset.id)")
    let interval = CMTimeMultiplyByFloat64(videoAsset.frameDuration, multiplier: 0.9)
    
    player?.addPeriodicTimeObserver(forInterval: interval, queue: queue) { [weak self] time in
      guard UserDefaults.standard.bool(forKey: PrefKeys.showAnnotations) else { return }

      guard let direction = self?.playDirection else { return }
      
      let elapsedTime = time.asMillis()
      let opposite = direction.opposite()
      
      self?.displayLayers(direction, at: elapsedTime)
      self?.clearLayers(opposite, at: elapsedTime)
    }
  }
}

/// Mouse selection
extension VideoPlayerView {
  private typealias LayerPoint = (layer: LocalizationLayer, point: CGPoint)
  
  override func mouseDown(with event: NSEvent) {
    let superPoint = event.locationInWindow
    
    if let selectedLayer = selectedLayer,
       selectedLayer.contains(superPoint) {
      selectedLocation = selectedLayer.location(of: superPoint)
      return
    }

    guard let mouseLayer = mouseLayer(point: event.locationInWindow) else {
      selectedLayer = nil
      selectedLocation = nil
      return
    }

    selectedLayer = mouseLayer
    let selectedPoint = selectedLayer!.convertSuperPoint(superPoint)
    selectedLocation = mouseLayer.location(of: selectedPoint)

    print("selected: \(String(describing: selectedLocation))")
  }
  
  override func mouseDragged(with event: NSEvent) {
    guard selectedLocation != nil else { return }
    
//    print("CxInc mouse dragged")
  }

  override func mouseExited(with event: NSEvent) {
    guard selectedLocation != nil else { return }
    
    print("CxInc mouse exit cancel current changes?")
    
    selectedLayer = nil
  }

  override func mouseUp(with event: NSEvent) {
    guard selectedLocation != nil else { return }
    
    print("CxInc mouse up")
  }
  
  private func mouseLayer(point: NSPoint) -> LocalizationLayer? {
    guard paused else { return nil }
    guard displayLocalizations else { return nil }
    guard let layers = localizations?.layers(.paused, at: currentTime) else { return nil }
    guard !layers.isEmpty else { return nil }
    
    let mousedLayers = layers.filter {
      $0.containsSuperPoint(point)
    }
    guard !mousedLayers.isEmpty else { return nil }
    
    let layer = mousedLayers.min { a, b in
      let aDistance = a.bounds.minSideDistance(point: point)
      let bDistance = b.bounds.minSideDistance(point: point)
      return aDistance < bDistance
    }!
    
    return layer
  }

}

