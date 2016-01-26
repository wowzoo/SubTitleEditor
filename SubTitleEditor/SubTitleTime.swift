//
//  SubTitleTime.swift
//  SubTitleEditor
//
//  Created by 장기현 on 2015. 12. 31..
//  Copyright © 2015년 JKH. All rights reserved.
//

import Foundation

class SubTitleTime {
    var milliseconds: Int
    
    init(milliseconds: Int) {
        self.milliseconds = milliseconds
    }
    
    // HH:mm:ss,SSS format
    init(timeInStr: String) {
        let delimiter = NSCharacterSet(charactersInString: ":,")
        let timeComponents = timeInStr.componentsSeparatedByCharactersInSet(delimiter)
        
        let hours: Int! = Int(timeComponents[0])
        let minutes: Int! = Int(timeComponents[1])
        let seconds: Int! = Int(timeComponents[2])
        let millis: Int! = Int(timeComponents[3])
        
        self.milliseconds = ((hours * 60 * 60) + (minutes * 60) + seconds) * 1000 + millis
    }
    
    func getReadableTime() -> String {
        var seconds = milliseconds / 1000
        let millis =  milliseconds % 1000
        var minutes = seconds / 60
        seconds %= 60
        let hours = minutes / 60
        minutes %= 60
        
        var readableTime: String = ""
        
        func changeFormat(timeComponent: Int, addDelimiter: Bool) {
            if timeComponent < 10 {
                readableTime.appendContentsOf("0\(timeComponent)")
            } else {
                readableTime.appendContentsOf("\(timeComponent)")
            }
            
            if addDelimiter {
                readableTime.appendContentsOf(":")
            }
        }
        
        changeFormat(hours, addDelimiter: true)
        changeFormat(minutes, addDelimiter: true)
        changeFormat(seconds, addDelimiter: false)
        
        switch millis {
        case 0..<10 :
            readableTime.appendContentsOf(",00\(millis)")
            break
        case 10..<100 :
            readableTime.appendContentsOf(",0\(millis)")
            break
        default :
            readableTime.appendContentsOf(",\(millis)")
            break
        }
        
        return readableTime
    }
}

/**
 For calculating duration
*/
func - (left: SubTitleTime, right: SubTitleTime) throws -> Int {
    if (left.milliseconds - right.milliseconds) < 0 {
        throw SubTitleError.ParseError(message: "End time(\(left.getReadableTime())) is less then Start time(\(right.getReadableTime()))")
    }
    
    return left.milliseconds - right.milliseconds
}

/**
 For time increase or decrease
*/
func - (left: SubTitleTime, right: Int) -> SubTitleTime {
    return SubTitleTime(milliseconds: left.milliseconds-right)
}

func + (left: SubTitleTime, right: Int) -> SubTitleTime {
    return SubTitleTime(milliseconds: left.milliseconds+right)
}