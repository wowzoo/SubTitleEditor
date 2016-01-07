//
//  StreamReader.swift
//  SubTitleEditor
//
//  Created by 장기현 on 2015. 12. 17..
//  Copyright © 2015년 JKH. All rights reserved.
//

import Cocoa

enum SubTitleReaderError: ErrorType {
    case InvalidEncoding(usedEncoding: UInt)
    case NoMoreLines
    case EndOfFile
    case InvalidNewline(delimiter: NSData)
}

class SubTitleReader {
    let encoding: NSStringEncoding
    let bufferSize: Int
    var lineCount: Int
    
    var fileHandle: NSFileHandle!
    let buffer: NSMutableData!
    let delimData: NSData!
    
    var atEof: Bool = false
    
    init?(path: String, delimiter: String = "\r\n", encoding: NSStringEncoding = NSUTF8StringEncoding, bufferSize: Int = 4096) {
        self.bufferSize = bufferSize
        self.encoding = encoding
        self.lineCount = 0
        
        guard let fileHandle = NSFileHandle(forReadingAtPath: path), let delimData = delimiter.dataUsingEncoding(encoding), let buffer = NSMutableData(capacity: bufferSize) else {
            self.fileHandle = nil
            self.delimData = nil
            self.buffer = nil
            
            return nil
        }
        
        self.fileHandle = fileHandle
        self.delimData = delimData
        self.buffer = buffer
    }
    
    deinit {
        self.close()
    }
    
    func close() {
        fileHandle?.closeFile()
        fileHandle = nil
    }
    
    /// Return next line, or nil on EOF.
    func nextLine() throws -> String? {
        precondition(fileHandle != nil, "Attempt to read from closed file")
        
        if atEof { throw SubTitleReaderError.EndOfFile }
        
        // Read data chunks from file until a line delimiter is found:
        var range = buffer.rangeOfData(delimData, options: [], range: NSMakeRange(0, buffer.length))
        while range.location == NSNotFound {
            let tmpData = fileHandle.readDataOfLength(bufferSize)
            if tmpData.length == 0 {
                guard lineCount != 0 else {
                    throw SubTitleReaderError.InvalidNewline(delimiter: delimData)
                }
                
                // EOF or read error.
                atEof = true
                guard buffer.length > 0 else {
                    // No more lines.
                    throw SubTitleReaderError.NoMoreLines
                }
                
                // Buffer contains last line in file (not terminated by delimiter).
                guard let line = NSString(data: buffer, encoding: encoding) else {
                    throw SubTitleReaderError.InvalidEncoding(usedEncoding: encoding)
                }
                
                buffer.length = 0
                return line as String?
            }
            
            buffer.appendData(tmpData)
            range = buffer.rangeOfData(delimData, options: [], range: NSMakeRange(0, buffer.length))
        }
        
        // Convert complete line (excluding the delimiter) to a string
        guard let line = NSString(data: buffer.subdataWithRange(NSMakeRange(0, range.location)), encoding: encoding)
            else { throw SubTitleReaderError.InvalidEncoding(usedEncoding: encoding) }
        
        // Remove line (and the delimiter) from the buffer:
        buffer.replaceBytesInRange(NSMakeRange(0, range.location + range.length), withBytes: nil, length: 0)
        
        // Increase Line Count
        lineCount++
        
        return line as String?
    }
}
