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

protocol SubTitleDoc {
    var url: NSURL! { get set }
    
    func getSubTitleData() throws -> [SubTitleData]
}


extension String {
    func getMatches(regex: String, options: NSRegularExpressionOptions) -> [NSTextCheckingResult]
    {
        var matches = [NSTextCheckingResult]()
        
        do {
            let exp = try NSRegularExpression(pattern: regex, options: options)
            matches = exp.matchesInString(self, options: [], range: NSMakeRange(0, self.characters.count))
        } catch let error as NSError {
            print(error)
        }
        
        return matches
    }
}