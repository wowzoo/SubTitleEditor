//
//  SubTitleDoc.swift
//  SubTitleEditor
//
//  Created by 장기현 on 2015. 12. 17..
//  Copyright © 2015년 JKH. All rights reserved.
//

import Cocoa

class SubTitleDoc4Srt: SubTitleDoc {
    //var data = [SubTitleData]()
    var url: NSURL!
    
    let encList = [
        //utf8
        NSUTF8StringEncoding,
        //euc-kr
        CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.EUC_KR.rawValue)),
        //cp949
        CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.DOSKorean.rawValue))
    ]
    
    init(fileURL: NSURL) {
        self.url = fileURL
    }
    
    func getSubTitleData() throws -> [SubTitleData] {
        
        guard let path = url.path else {
            throw SubTitleError.InvalidURLPath
        }
        
        var encIndex: Int = 0
        var delimiter = "\r\n"
        var subList: [String] = [String]()
        
        while encIndex < encList.count {
            guard let sReader = SubTitleReader(path: path, delimiter: delimiter, encoding: encList[encIndex]) else {
                throw SubTitleError.StreamOpenError
            }
            
            defer {
                print("file closed")
                sReader.close()
            }
            
            /* SRT File Format
            It consists of four parts, all in text..
            
            1. A numeric counter identifying each sequential subtitle
            2. The time that the subtitle should appear on the screen, followed by --> and the time it should disappear
            3. Subtitle text itself on one or more lines
            4. A blank line containing no text, indicating the end of this subtitle[9]
            */
            var count: Int = 1
            
            do {
                while let line = try sReader.nextLine() {
                    
                    if line.isEmpty {
                        continue
                    } else if line == String(count) {
                        count++
                        continue
                    } else {
                        subList.append(line)
                    }
                }
                
            } catch SubTitleReaderError.EndOfFile {
                print("End Of File (total lines : \(sReader.lineCount))")
                break
            } catch SubTitleReaderError.NoMoreLines {
                print("No More Lines (total lines : \(sReader.lineCount))")
                break
            } catch SubTitleReaderError.InvalidEncoding(let usedEncoding) {
                print(NSString.localizedNameOfStringEncoding(usedEncoding) + " is invalid encoding")
                subList.removeAll()
                encIndex++
                continue
            } catch SubTitleReaderError.InvalidNewline(let delim) {
                print(String(delim) + " is invalid newline")
                subList.removeAll()
                delimiter = "\n"
                continue
            } catch let error as NSError {
                throw SubTitleError.UnknownError(error: error)
            }
        }
        
        do {
            return try parseSRT(subList)
        } catch let error {
            throw error
        }
    }
    
    func parseSRT(subList: [String]) throws -> [SubTitleData] {
        //var sequentialNumber: Int = 1
        var startTime: String = ""
        var endTime: String = ""
        var text: String = ""
        var duration: String = ""
        
        let regex4Interval = "^([0-9]{2}:[0-9]{2}:[0-9]{2},[0-9]{3})\\s-->\\s([0-9]{2}:[0-9]{2}:[0-9]{2},[0-9]{3})$"
        
        var data: [SubTitleData] = [SubTitleData]()
        var datum: SubTitleData? = nil
        
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
                
                datum = SubTitleData(start: startTime, end: endTime, text: "", duration: duration)
                
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
            
            let subData = SubTitleData(start: startTime, end: endTime, text: " ", duration: "00:00:01,000")
            
            data.append(subData)
        }
        
        return data
    }

}
