import Foundation
import AVFoundation

open class Cephalopod: NSObject {
  static let defaultFadeDurationSeconds = 3.0
  static let defaultVelocity = 2.0

  let player: AVAudioPlayer
  var timer: AutoCancellingTimer?
  
  // The higher the number - the higher the quality of fade
  // and it will consume more CPU.
  var volumeAlterationsPerSecond = 30.0
  
  private var fadeDurationSeconds = defaultFadeDurationSeconds
  private var fadeVelocity = defaultVelocity
  
  private var fromVolume = 0.0
  private var toVolume = 0.0
  
  private var currentStep = 0
  
  private var onFinished: ((Bool)->())? = nil
  
  public init(player: AVAudioPlayer) {
    self.player = player
  }
  
  deinit {
    callOnFinished(finished: false)
    stop()
  }
  
  private var fadeIn: Bool {
    return fromVolume < toVolume
  }
  
  open func fadeIn(duration: Double = defaultFadeDurationSeconds,
                   velocity: Double = defaultVelocity, onFinished: ((Bool)->())? = nil) {
    
    fade(
      fromVolume: Double(player.volume), toVolume: 1,
      duration: duration, velocity: velocity, onFinished: onFinished)
  }
  
  open func fadeOut(duration: Double = defaultFadeDurationSeconds,
                    velocity: Double = defaultVelocity, onFinished: ((Bool)->())? = nil) {
    
    fade(
      fromVolume: Double(player.volume), toVolume: 0,
      duration: duration, velocity: velocity, onFinished: onFinished)
  }
  
  open func fade(fromVolume: Double, toVolume: Double,
                 duration: Double = defaultFadeDurationSeconds,
                 velocity: Double = defaultVelocity, onFinished: ((Bool)->())? = nil) {
    
    self.fromVolume = Cephalopod.makeSureValueIsBetween0and1(value: fromVolume)
    self.toVolume = Cephalopod.makeSureValueIsBetween0and1(value: toVolume)
    self.fadeDurationSeconds = duration
    self.fadeVelocity = velocity
    
    callOnFinished(finished: false)
    self.onFinished = onFinished
    
    player.volume = Float(self.fromVolume)
    
    if self.fromVolume == self.toVolume {
      callOnFinished(finished: true)
      return
    }
    
    startTimer()
  }
  
  // Stop fading. Does not stop the sound.
  open func stop() {
    stopTimer()
  }
  
  private func callOnFinished(finished: Bool) {
    onFinished?(finished)
    onFinished = nil
  }
  
  private func startTimer() {
    stopTimer()
    currentStep = 0
    
    let delay =  1 / volumeAlterationsPerSecond
    
    timer = AutoCancellingTimer(interval: delay, repeats: true) { [weak self] in
      self?.timerFired();
    }
  }
  
  private func stopTimer() {
    if let currentTimer = timer {
      currentTimer.cancel()
      timer = nil
    }
  }
  
  func timerFired() {
    if shouldStopTimer {
      player.volume = Float(toVolume)
      stopTimer()
      callOnFinished(finished: true)
      return
    }
    
    let currentTimeFrom0To1 = Cephalopod.timeFrom0To1(
      currentStep: currentStep, fadeDurationSeconds: fadeDurationSeconds, volumeAlterationsPerSecond: volumeAlterationsPerSecond)
    
    var volumeMultiplier: Double
    
    var newVolume: Double = 0
    
    if fadeIn {
      volumeMultiplier = Cephalopod.fadeInVolumeMultiplier(timeFrom0To1: currentTimeFrom0To1,
                                                      velocity: fadeVelocity)
      
      newVolume = fromVolume + (toVolume - fromVolume) * volumeMultiplier
      
    } else {
      volumeMultiplier = Cephalopod.fadeOutVolumeMultiplier(timeFrom0To1: currentTimeFrom0To1,
                                                       velocity: fadeVelocity)
      
      newVolume = toVolume - (toVolume - fromVolume) * volumeMultiplier
    }
    
    player.volume = Float(newVolume)
    
    currentStep += 1
  }
  
  var shouldStopTimer: Bool {
    let totalSteps = fadeDurationSeconds * volumeAlterationsPerSecond
    return Double(currentStep) > totalSteps
  }
  
  class func timeFrom0To1(currentStep: Int, fadeDurationSeconds: Double,
                          volumeAlterationsPerSecond: Double) -> Double {
    
    let totalSteps = fadeDurationSeconds * volumeAlterationsPerSecond
    var result = Double(currentStep) / totalSteps
    
    result = makeSureValueIsBetween0and1(value: result)
    
    return result
  }
  
  // Graph: https://www.desmos.com/calculator/wnstesdf0h
  class func fadeOutVolumeMultiplier(timeFrom0To1: Double, velocity: Double) -> Double {
    let time = makeSureValueIsBetween0and1(value: timeFrom0To1)
    return pow(M_E, -velocity * time) * (1 - time)
  }
  
  class func fadeInVolumeMultiplier(timeFrom0To1: Double, velocity: Double) -> Double {
    let time = makeSureValueIsBetween0and1(value: timeFrom0To1)
    return pow(M_E, velocity * (time - 1)) * time
  }
  
  private class func makeSureValueIsBetween0and1(value: Double) -> Double {
    if value < 0 { return 0 }
    if value > 1 { return 1 }
    return value
  }
}
