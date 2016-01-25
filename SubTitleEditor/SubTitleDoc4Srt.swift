//
//  SubTitleDoc.swift
//  SubTitleEditor
//
//  Created by 장기현 on 2015. 12. 17..
//  Copyright © 2015년 JKH. All rights reserved.
//

import Cocoa

class SubTitleDoc4Srt: SubTitleDoc {
    
    override func parse() throws -> [SubTitleData] {
        let subList: [String] = try getManagedLines()
        
        //var sequentialNumber: Int = 1
        var startTime: String = ""
        var endTime: String = ""
        var text: String = ""
        var duration: String = ""
        
        let regex4Interval = "^([0-9]{2}:[0-9]{2}:[0-9]{2},[0-9]{3})\\s-->\\s([0-9]{2}:[0-9]{2}:[0-9]{2},[0-9]{3})$"
        
        var data: [SubTitleData] = [SubTitleData]()
        var datum: SubTitleData? = nil
        
        var itemNum: Int = 0
        for subLine in subList {
            //print(subLine)
            let matches = subLine.getMatches(regex4Interval, options: [])
            if matches.count > 1 {
                throw SubTitleError.ParseError(message: subLine)
            }
            
            if matches.count == 1 {
                if let item = datum {
                    if !text.isEmpty {
                        let index: String.Index = text.startIndex.advancedBy(4)
                        let trimmedText = text.substringFromIndex(index)
                        
                        item.text = trimmedText
                    }
                    
                    data.append(item)
                    text = ""
                }
                
                let match: NSTextCheckingResult = matches[0]
                //let r0 = match.rangeAtIndex(0)
                let r1 = match.rangeAtIndex(1)
                let r2 = match.rangeAtIndex(2)
                
                startTime = (subLine as NSString).substringWithRange(r1)
                endTime = (subLine as NSString).substringWithRange(r2)
                
                let sTime = SubTitleTime(timeInStr: startTime)
                let eTime = SubTitleTime(timeInStr: endTime)
                duration = SubTitleTime(milliseconds: eTime - sTime).getReadableTime()
                
                datum = SubTitleData(num: itemNum++, start: startTime, end: endTime, text: "", duration: duration)
                
            } else {
                text += "<br>\(subLine)"
            }
        }
        
        //add last subtitle data
        let index: String.Index = text.startIndex.advancedBy(4)
        let trimmedText = text.substringFromIndex(index)
        
        let item: SubTitleData! = datum
        item.text = trimmedText
        data.append(item)
        
        //and check if the last text is " "
        //if not then add additional text data with " "
        if item.text != " " {
            startTime = item.end
            let eTime = SubTitleTime(timeInStr: startTime) + 1000
            endTime = eTime.getReadableTime()
            
            let subData = SubTitleData(num: itemNum, start: startTime, end: endTime, text: " ", duration: "00:00:01,000")
            
            data.append(subData)
        }
        
        return data
    }
    
    func getManagedLines() throws -> [String] {
        var subList: [String] = [String]()
        
        let lines = try super.getLines()
        
        /* SRT File Format
        * It consists of four parts, all in text..
        * 1. A numeric counter identifying each sequential subtitle
        * 2. The time that the subtitle should appear on the screen, followed by --> and the time it should disappear
        * 3. Subtitle text itself on one or more lines
        * 4. A blank line containing no text, indicating the end of this subtitle[9]
        */
        var count: Int = 1
        
        for line in lines {
            if line.isEmpty {
                continue
            } else if line == String(count) {
                count++
                continue
            } else {
                subList.append(line)
            }
        }
        
        return subList
    }
}
