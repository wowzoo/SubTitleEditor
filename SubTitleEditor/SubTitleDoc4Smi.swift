//
//  SubTitleDoc4Smi.swift
//  SubTitleEditor
//
//  Created by 장기현 on 2015. 12. 26..
//  Copyright © 2015년 JKH. All rights reserved.
//

import Cocoa

class SubTitleDoc4Smi: SubTitleDoc {
    var url: NSURL!
    
    init(fileURL: NSURL) {
        self.url = fileURL
    }
    
    func parse() throws -> [SubTitleData] {
        guard let path = url.path else {
            throw SubTitleError.InvalidURLPath
        }
        
        let subList: [String] = try getManagedLines(path)
        
        guard subList.count != 0 else {
            throw SubTitleError.ParseError(message: "This is not SMI format file")
        }
        
        let regex = "^<\\s*SYNC\\s+Start\\s*=\\s*([0-9]+)\\s*><\\s*P\\s+Class\\s*=\\s*[a-z]+\\s*>(<br>)*(.*)"
        var data = [SubTitleData]()
        
        var itemNum: Int = 0
        for subLine in subList {
            //print(subLine)
            let matches = subLine.getMatches(regex, options: .CaseInsensitive)
            if matches.count == 0 {
                print(subLine)
                data.removeAll()
                //return nil
                
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
            
            //print(millisec)
            //print(text)
            if text.isEmpty || text.lowercaseString == "&nbsp;" || text.lowercaseString == "&nbsp" {
                let lastData: SubTitleData! = data.popLast()
                let eTime = SubTitleTime(milliseconds: millisec)
                
                lastData.end = eTime.getReadableTime()
                
                let sTime = SubTitleTime(timeInStr: lastData.start)
                
                lastData.duration = SubTitleTime(milliseconds: eTime - sTime).getReadableTime()
                
                data.append(lastData)
            } else {
                //let number = String(data.count + 1)
                if let lastData: SubTitleData = data.popLast() {
                    if lastData.end.isEmpty {
                        let sTime = SubTitleTime(timeInStr: lastData.start)
                        let eTime = SubTitleTime(milliseconds: millisec)
                        lastData.end = eTime.getReadableTime()
                        lastData.duration = SubTitleTime(milliseconds: eTime - sTime).getReadableTime()
                    }
                    data.append(lastData)
                }
                let sTime = SubTitleTime(milliseconds: millisec)
                
                //if text.isEmpty {
                //    text = " "
                //}
                
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
            item.duration = SubTitleTime(milliseconds: eTime - sTime).getReadableTime()
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
    
    func getManagedLines(path: String) throws -> [String] {
        var subList: [String] = [String]()
        
        let fileHandle: NSFileHandle! = NSFileHandle(forReadingAtPath: path)
        let tmpData = fileHandle.readDataToEndOfFile()
        fileHandle.closeFile()
        
        var convertedString: NSString?
        let enc = NSString.stringEncodingForData(tmpData, encodingOptions: nil, convertedString: &convertedString, usedLossyConversion: nil)
        
        print(NSString.localizedNameOfStringEncoding(enc) + " is used")
        
        guard let lines = convertedString?.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet()) else {
            throw SubTitleError.ParseError(message: "Separating Newline Error")
        }
        
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
                
                subList.append(collectedString)
                collectedString = ""
            } else {
                if !collectedString.isEmpty {
                    collectedString += line
                }
            }
        }
        
        return subList
    }
}