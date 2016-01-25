//
//  SubTitleDocProtocol.swift
//  SubTitleEditor
//
//  Created by 장기현 on 2015. 12. 26..
//  Copyright © 2015년 JKH. All rights reserved.
//

import Foundation

enum SubTitleError: ErrorType {
    case ParseError(message: String)
    case InvalidURLPath
    case StreamOpenError
    case UnknownError(error: NSError)
}

class SubTitleDoc {
    var encoding: String {
        get {
            return String.localizedNameOfStringEncoding(self.enc)
        }
    }
    
    var filePathWithoutExt: String {
        get {
            return url.URLByDeletingPathExtension!.path!
        }
    }
    
    var fileName: String {
        get {
            return url.URLByDeletingPathExtension!.lastPathComponent!
        }
    }
    
    var fileExtension: String {
        get {
            return url.pathExtension!
        }
    }
    
    var url: NSURL!
    var enc: UInt
    
    init(fileURL: NSURL) {
        self.url = fileURL
        self.enc = NSUTF8StringEncoding
    }
    
    func getLines() throws -> [String] {
        guard let path = url.path else {
            throw SubTitleError.InvalidURLPath
        }
        
        let fileHandle: NSFileHandle! = NSFileHandle(forReadingAtPath: path)
        let tmpData = fileHandle.readDataToEndOfFile()
        fileHandle.closeFile()
        
        var convertedString: NSString?
        self.enc = NSString.stringEncodingForData(tmpData, encodingOptions: nil, convertedString: &convertedString, usedLossyConversion: nil)
        
        //print(String.localizedNameOfStringEncoding(enc) + " is used")
        
        guard let lines = convertedString?.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet()) else {
            throw SubTitleError.ParseError(message: "Separating Newline Error")
        }
        
        return lines
    }
    
    func parse() throws -> [SubTitleData] {
        fatalError("must be overridden")
    }
}


extension String {
    func getMatches(regex: String, options: NSRegularExpressionOptions) -> [NSTextCheckingResult]
    {
        var matches: [NSTextCheckingResult]?
        
        do {
            let exp = try NSRegularExpression(pattern: regex, options: options)
            matches = exp.matchesInString(self, options: [], range: NSMakeRange(0, self.characters.count))
        } catch let error as NSError {
            fatalError(error.debugDescription)
        }
        
        return matches!
    }
}