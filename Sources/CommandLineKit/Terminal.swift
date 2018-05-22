//
//  Terminal.swift
//  CommandLineKit
//
//  Created by Matthias Zenger on 19/04/2018.
//  Copyright © 2018 Google LLC
//  Copyright © 2017 Andy Best <andybest.net at gmail dot com>
//  Copyright © 2010-2014 Salvatore Sanfilippo <antirez at gmail dot com>
//  Copyright © 2010-2013 Pieter Noordhuis <pcnoordhuis at gmail dot com>
//
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  * Redistributions of source code must retain the above copyright notice,
//    this list of conditions and the following disclaimer.
//
//  * Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
//  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
//  ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

import Foundation

public struct Terminal {
  
  public static let current: String = ProcessInfo.processInfo.environment["TERM"] ?? ""
  
  public static var fullColorSupport: Bool {
    return Terminal.fullColorSupport(termVar: Terminal.current)
  }
  
  public static func fullColorSupport(termVar: String) -> Bool {
    // A rather dumb way of detecting colour support
    return termVar.contains("256")
  }
  
  // Colour tables from https://jonasjacek.github.io/colors/
  // Format: (r, g, b)
  
  private static let colors: [(UInt8, UInt8, UInt8)] = [
    // Standard
    (0, 0, 0), (128, 0, 0), (0, 128, 0), (128, 128, 0), (0, 0, 128), (128, 0, 128),
    (0, 128, 128), (192, 192, 192),
    // High intensity
    (128, 128, 128), (255, 0, 0), (0, 255, 0), (255, 255, 0), (0, 0, 255), (255, 0, 255),
    (0, 255, 255), (255, 255, 255),
    // 256 color extended
    (0, 0, 0), (0, 0, 95), (0, 0, 135), (0, 0, 175), (0, 0, 215), (0, 0, 255), (0, 95, 0),
    (0, 95, 95), (0, 95, 135), (0, 95, 175), (0, 95, 215), (0, 95, 255), (0, 135, 0),
    (0, 135, 95), (0, 135, 135), (0, 135, 175), (0, 135, 215), (0, 135, 255), (0, 175, 0),
    (0, 175, 95), (0, 175, 135), (0, 175, 175), (0, 175, 215), (0, 175, 255), (0, 215, 0),
    (0, 215, 95), (0, 215, 135), (0, 215, 175), (0, 215, 215), (0, 215, 255), (0, 255, 0),
    (0, 255, 95), (0, 255, 135), (0, 255, 175), (0, 255, 215), (0, 255, 255), (95, 0, 0),
    (95, 0, 95), (95, 0, 135), (95, 0, 175), (95, 0, 215), (95, 0, 255), (95, 95, 0),
    (95, 95, 95), (95, 95, 135), (95, 95, 175), (95, 95, 215), (95, 95, 255), (95, 135, 0),
    (95, 135, 95), (95, 135, 135), (95, 135, 175), (95, 135, 215), (95, 135, 255), (95, 175, 0),
    (95, 175, 95), (95, 175, 135), (95, 175, 175), (95, 175, 215), (95, 175, 255), (95, 215, 0),
    (95, 215, 95), (95, 215, 135), (95, 215, 175), (95, 215, 215), (95, 215, 255), (95, 255, 0),
    (95, 255, 95), (95, 255, 135), (95, 255, 175), (95, 255, 215), (95, 255, 255), (135, 0, 0),
    (135, 0, 95), (135, 0, 135), (135, 0, 175), (135, 0, 215), (135, 0, 255), (135, 95, 0),
    (135, 95, 95), (135, 95, 135), (135, 95, 175), (135, 95, 215), (135, 95, 255), (135, 135, 0),
    (135, 135, 95), (135, 135, 135), (135, 135, 175), (135, 135, 215), (135, 135, 255),
    (135, 175, 0), (135, 175, 95), (135, 175, 135), (135, 175, 175), (135, 175, 215),
    (135, 175, 255), (135, 215, 0), (135, 215, 95), (135, 215, 135), (135, 215, 175),
    (135, 215, 215), (135, 215, 255), (135, 255, 0), (135, 255, 95), (135, 255, 135),
    (135, 255, 175), (135, 255, 215), (135, 255, 255), (175, 0, 0), (175, 0, 95), (175, 0, 135),
    (175, 0, 175), (175, 0, 215), (175, 0, 255), (175, 95, 0), (175, 95, 95), (175, 95, 135),
    (175, 95, 175), (175, 95, 215), (175, 95, 255), (175, 135, 0), (175, 135, 95),
    (175, 135, 135), (175, 135, 175), (175, 135, 215), (175, 135, 255), (175, 175, 0),
    (175, 175, 95), (175, 175, 135), (175, 175, 175), (175, 175, 215), (175, 175, 255),
    (175, 215, 0), (175, 215, 95), (175, 215, 135), (175, 215, 175), (175, 215, 215),
    (175, 215, 255), (175, 255, 0), (175, 255, 95), (175, 255, 135), (175, 255, 175),
    (175, 255, 215), (175, 255, 255), (215, 0, 0), (215, 0, 95), (215, 0, 135), (215, 0, 175),
    (215, 0, 215), (215, 0, 255), (215, 95, 0), (215, 95, 95), (215, 95, 135), (215, 95, 175),
    (215, 95, 215), (215, 95, 255), (215, 135, 0), (215, 135, 95), (215, 135, 135),
    (215, 135, 175), (215, 135, 215), (215, 135, 255), (215, 175, 0), (215, 175, 95),
    (215, 175, 135), (215, 175, 175), (215, 175, 215), (215, 175, 255), (215, 215, 0),
    (215, 215, 95), (215, 215, 135), (215, 215, 175), (215, 215, 215), (215, 215, 255),
    (215, 255, 0), (215, 255, 95), (215, 255, 135), (215, 255, 175), (215, 255, 215),
    (215, 255, 255), (255, 0, 0), (255, 0, 95), (255, 0, 135), (255, 0, 175), (255, 0, 215),
    (255, 0, 255), (255, 95, 0), (255, 95, 95), (255, 95, 135), (255, 95, 175), (255, 95, 215),
    (255, 95, 255), (255, 135, 0), (255, 135, 95), (255, 135, 135), (255, 135, 175),
    (255, 135, 215), (255, 135, 255), (255, 175, 0), (255, 175, 95), (255, 175, 135),
    (255, 175, 175), (255, 175, 215), (255, 175, 255), (255, 215, 0), (255, 215, 95),
    (255, 215, 135), (255, 215, 175), (255, 215, 215), (255, 215, 255), (255, 255, 0),
    (255, 255, 95), (255, 255, 135), (255, 255, 175), (255, 255, 215), (255, 255, 255),
    (8, 8, 8), (18, 18, 18), (28, 28, 28), (38, 38, 38), (48, 48, 48), (58, 58, 58),
    (68, 68, 68), (78, 78, 78), (88, 88, 88), (98, 98, 98), (108, 108, 108), (118, 118, 118),
    (128, 128, 128), (138, 138, 138), (148, 148, 148), (158, 158, 158), (168, 168, 168),
    (178, 178, 178), (188, 188, 188), (198, 198, 198), (208, 208, 208), (218, 218, 218),
    (228, 228, 228), (238, 238, 238)
  ]
  
  internal static func closestColor(to targetColor: (UInt8, UInt8, UInt8),
                                    fullColorSupport all256: Bool = false) -> UInt8 {
    let colorTable: [(UInt8, UInt8, UInt8)] = all256 ? colors : Array(colors[0..<8])
    let distances = colorTable.map {
      sqrt(pow(Double(Int($0.0) - Int(targetColor.0)), 2) +
           pow(Double(Int($0.1) - Int(targetColor.1)), 2) +
           pow(Double(Int($0.2) - Int(targetColor.2)), 2))
    }
    var closest = Double.greatestFiniteMagnitude
    var closestIdx = 0
    for i in 0..<distances.count {
      if distances[i] < closest  {
        closest = distances[i]
        closestIdx = i
      }
    }
    return UInt8(closestIdx)
  }
}
