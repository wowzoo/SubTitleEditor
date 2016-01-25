//
//  SubTitleDocFactory.swift
//  SubTitleEditor
//
//  Created by 장기현 on 2015. 12. 27..
//  Copyright © 2015년 JKH. All rights reserved.
//

import Foundation

class SubTitleDocFactory {
    class func Create(fileURL: NSURL) -> SubTitleDoc? {
        if let ext = fileURL.pathExtension {
            if ext == "srt" {
                return SubTitleDoc4Srt(fileURL: fileURL)
            } else if ext == "smi" {
                return SubTitleDoc4Smi(fileURL: fileURL)
            }
        }
        
        return nil
    }
    
}