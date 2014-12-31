//
//  SliderDefaults.swift
//  SpringAnimationCALayer
//
//  Created by Evgenii Neumerzhitckii on 1/11/2014.
//  Copyright (c) 2014 Evgenii Neumerzhitckii. All rights reserved.
//

import UIKit

struct SliderDefaults {
  let value: Double
  let minimumValue: Double
  let maximumValue: Double
  var valueNames = [Double:String]()
  var step:Double = 0

  init(value: Double, minimumValue: Double, maximumValue: Double) {
    self.value = value;
    self.minimumValue = minimumValue
    self.maximumValue = maximumValue
  }

  static func set(slider: UISlider, defaults: SliderDefaults) {
    slider.minimumValue = Float(defaults.minimumValue)
    slider.maximumValue = Float(defaults.maximumValue)
    slider.value = Float(defaults.value)
  }
}
