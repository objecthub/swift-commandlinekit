//
//  ControlCharacters.swift
//  CommandLineKit
//
//  Created by Matthias Zenger on 07/04/2018.
//  Copyright © 2018 Google LLC
//  Copyright © 2017 Andy Best <andybest.net at gmail dot com>
//  Copyright © 2010-2014, Salvatore Sanfilippo <antirez at gmail dot com>
//  Copyright © 2010-2013, Pieter Noordhuis <pcnoordhuis at gmail dot com>
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

public enum ControlCharacters: UInt8 {
  case Null = 0
  case CtrlA = 1
  case CtrlB = 2
  case CtrlC = 3
  case CtrlD = 4
  case CtrlE = 5
  case CtrlF = 6
  case Bell = 7
  case CtrlH = 8
  case Tab = 9
  case CtrlK = 11
  case CtrlL = 12
  case Enter = 13
  case CtrlN = 14
  case CtrlP = 16
  case CtrlT = 20
  case CtrlU = 21
  case CtrlW = 23
  case Esc = 27
  case Backspace = 127
  
  var character: Character {
    return Character(UnicodeScalar(Int(self.rawValue))!)
  }
}
