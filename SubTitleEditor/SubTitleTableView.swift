//
//  SubTitleTableView.swift
//  SubTitleEditor
//
//  Created by 장기현 on 2016. 1. 6..
//  Copyright © 2016년 JKH. All rights reserved.
//

import Cocoa

class SubTitleTableView: NSTableView {

    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        // Drawing code here.
    }
    
    override func menuForEvent(event: NSEvent) -> NSMenu? {
        super.menuForEvent(event)
        
        //Find cursor location
        let cursorPoint: NSPoint = self.convertPoint(event.locationInWindow, fromView: nil)
        let row: Int = self.rowAtPoint(cursorPoint)
        
        //check if the row is aleady selected
        //if not, then select the row and deselect others
        let isRowAleadySelected: Bool = self.selectedRowIndexes.containsIndex(row)
        if !isRowAleadySelected {
            self.selectRowIndexes(NSIndexSet(index: row), byExtendingSelection: false)
        }
        
        return self.menu
    }
    
}
