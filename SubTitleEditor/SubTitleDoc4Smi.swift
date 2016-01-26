//
//  SubTitleDoc4Smi.swift
//  SubTitleEditor
//
//  Created by 장기현 on 2015. 12. 26..
//  Copyright © 2015년 JKH. All rights reserved.
//

import Cocoa

class SubTitleDoc4Smi: SubTitleDoc {    
    
    override func parse() throws -> [SubTitleData] {
        let subList: [String] = try getManagedLines()
        
        guard subList.count != 0 else {
            throw SubTitleError.ParseError(message: "This is not SMI format file")
        }
        
        let regex = "^<\\s*SYNC\\s+Start\\s*=\\s*([0-9]+)\\s*><\\s*P\\s+Class\\s*=\\s*[a-z_]+\\s*>(<br>|&nbsp;?)*(.*)"
        var data = [SubTitleData]()
        
        var itemNum: Int = 0
        for subLine in subList {
            //print(subLine)
            let matches = subLine.getMatches(regex, options: .CaseInsensitive)
            if matches.count == 0 {
                //print(subLine)
                data.removeAll()
                
                throw SubTitleError.ParseError(message: subLine)
            }
            
            let match: NSTextCheckingResult = matches[0]
            var millisec: Int!
            var text: String
            
            if match.numberOfRanges == 3 {
                millisec = Int((subLine as NSString).substringWithRange(match.rangeAtIndex(1)))
                text = (subLine as NSString).substringWithRange(match.rangeAtIndex(2))
            } else if match.numberOfRanges == 4 {
                millisec = Int((subLine as NSString).substringWithRange(match.rangeAtIndex(1)))
                text = (subLine as NSString).substringWithRange(match.rangeAtIndex(3))
            } else {
                throw SubTitleError.ParseError(message: "RegularExpression Matching is Wrong")
            }
            
            if text.isEmpty {
                guard let lastData: SubTitleData = data.popLast() else {
                    continue
                }
                
                let eTime = SubTitleTime(milliseconds: millisec)
                lastData.end = eTime.getReadableTime()
                
                let sTime = SubTitleTime(timeInStr: lastData.start)
                
                do {
                    lastData.duration = try SubTitleTime(milliseconds: eTime - sTime).getReadableTime()
                } catch SubTitleError.ParseError(let message) {
                    throw SubTitleError.ParseError(message: "\(message) : \(subLine)")
                }
                
                data.append(lastData)
            } else {
                if let lastData: SubTitleData = data.popLast() {
                    if lastData.end.isEmpty {
                        let sTime = SubTitleTime(timeInStr: lastData.start)
                        let eTime = SubTitleTime(milliseconds: millisec)
                        lastData.end = eTime.getReadableTime()
                        do {
                            lastData.duration = try SubTitleTime(milliseconds: eTime - sTime).getReadableTime()
                        } catch SubTitleError.ParseError(let message) {
                            throw SubTitleError.ParseError(message: "\(message) : \(subLine)")
                        }
                    }
                    data.append(lastData)
                }
                let sTime = SubTitleTime(milliseconds: millisec)
                
                let subData = SubTitleData(num: itemNum++, start: sTime.getReadableTime(), end: "", text: text, duration: "")
                data.append(subData)
            }
        }
        
        let item = data[data.count - 1]
        
        //check if the last line is not end with &nbsp;
        //if so, then add end time
        if item.end.isEmpty {
            let startTime = item.start
            let sTime = SubTitleTime(timeInStr: startTime)
            let eTime = sTime + 3000
            item.end = eTime.getReadableTime()
            
            //never raise exception
            item.duration = try SubTitleTime(milliseconds: eTime - sTime).getReadableTime()
        }
        
        //and check if the last text is " "
        //if not then add additional text data with " "
        if item.text != " " {
            let startTime = item.end
            let eTime = SubTitleTime(timeInStr: startTime) + 1000
            let endTime = eTime.getReadableTime()
            
            let subData = SubTitleData(num: itemNum, start: startTime, end: endTime, text: " ", duration: "00:00:01,000")
            
            data.append(subData)
        }
        
        return data
    }
    
    func getManagedLines() throws -> [String] {
        var subList: [String] = [String]()
        
        let lines = try super.getLines()
        
        var collectedString: String = ""
        
        for line in lines {
            //print(line)
            if let range = line.rangeOfString("<SYNC Start", options: .CaseInsensitiveSearch) {
                // if the line does not start with <SYNC Start
                if range.startIndex != line.startIndex {
                    if !collectedString.isEmpty {
                        collectedString += line.substringToIndex(range.startIndex)
                        subList.append(collectedString)
                    }
                    collectedString = line.substringFromIndex(range.startIndex)
                } else {
                    if !collectedString.isEmpty {
                        subList.append(collectedString)
                    }
                    collectedString = line
                }
            } else if let range = line.rangeOfString("</BODY>", options: .CaseInsensitiveSearch) {
                if range.startIndex != line.startIndex {
                    collectedString += line.substringToIndex(range.startIndex)
                }
                
                if !collectedString.isEmpty {
                    subList.append(collectedString)
                    collectedString = ""
                }
            } else {
                if !collectedString.isEmpty {
                    collectedString += line
                }
            }
        }
        
        return subList
    }
}