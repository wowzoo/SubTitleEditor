//
//  SubTitleData.swift
//  SubTitleEditor
//
//  Created by 장기현 on 2015. 12. 16..
//  Copyright © 2015년 JKH. All rights reserved.
//

import Cocoa

class SubTitleData {
    var num: Int = 0
    var start: String = ""
    var end: String = ""
    var duration: String = ""
    var text: String = ""
    
    init(num: Int, start: String, end: String, text: String, duration: String) {
        self.num = num
        self.start = start
        self.end = end
        self.text = text
        self.duration = duration
    }
}
