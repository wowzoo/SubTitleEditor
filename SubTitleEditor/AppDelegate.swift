//
//  AppDelegate.swift
//  SubTitleEditor
//
//  Created by 장기현 on 2015. 12. 15..
//  Copyright © 2015년 JKH. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationShouldHandleReopen(sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        
        if !flag {
            for window in sender.windows {
                window.makeKeyAndOrderFront(self)
            }
        }
        
        return true
    }

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
    
    func application(sender: NSApplication, openFile filename: String) -> Bool {
        //print(filename)
        
        for window in sender.windows {
            if !window.visible {
                window.makeKeyAndOrderFront(self)
            }
            
            window.contentViewController?.representedObject = NSURL(fileURLWithPath: filename)
        }
        
//        guard let controller = NSApplication.sharedApplication().mainWindow?.contentViewController as? ViewController else {
//            return false
//        }
//        
//        controller.representedObject = url
        
        return true
    }
}

