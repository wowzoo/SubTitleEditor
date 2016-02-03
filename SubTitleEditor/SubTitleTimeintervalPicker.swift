//
//  SubTitleTimeintervalPicker.swift
//  SubTitleEditor
//
//  Created by 장기현 on 2016. 1. 30..
//  Copyright © 2016년 JKH. All rights reserved.
//

import Cocoa

class SubTitleTimeIntervalCell: NSTextFieldCell {
    let size: NSSize?
    let max: Int?
    let formatString: String?
    let limit: Int?
    
    var right: SubTitleTimeIntervalCell?
    var left: SubTitleTimeIntervalCell?
    
    var frame: NSRect?
    
    override var integerValue: Int {
        didSet {
            super.stringValue = String(format: self.formatString!, integerValue)
        }
    }
    
    init(textCell: String, size: NSSize, max: Int, formatString: String?, limit: Int) {
        self.size = size
        self.max = max
        self.formatString = formatString
        self.limit = limit
        
        super.init(textCell: textCell)
    }

    required init?(coder aDecoder: NSCoder) {
        self.size = nil
        self.max = nil
        self.formatString = nil
        self.limit = nil
        
        super.init(coder: aDecoder)
    }
   
    override func drawWithFrame(cellFrame: NSRect, inView controlView: NSView) {
        super.drawWithFrame(cellFrame, inView: controlView)
        
        self.frame = cellFrame
    }
    
    func updateValue(amount: Int) -> String {
        var value: Int = 0
        let current: Int = Int(self.stringValue)!
        
        if current >= self.limit {
            value = amount
        } else {
            value = current * 10 + amount
            if value > self.max {
                value = amount
            }
        }
        
        self.integerValue = value
        
        return self.stringValue
    }
    
    func setNeighbors(left: SubTitleTimeIntervalCell?, right: SubTitleTimeIntervalCell?) {
        self.left = left
        self.right = right
    }
}

@IBDesignable
class SubTitleTimeintervalPicker: NSControl, NSTextViewDelegate {
    var hoursCell: SubTitleTimeIntervalCell?
    var minutesCell: SubTitleTimeIntervalCell?
    var secondsCell: SubTitleTimeIntervalCell?
    var millisecondsCell: SubTitleTimeIntervalCell?
    
    var separatorCell1: SubTitleTimeIntervalCell?
    var separatorCell2: SubTitleTimeIntervalCell?
    var separatorCell3: SubTitleTimeIntervalCell?
    
    var stepperCell: NSStepperCell?
    var stepperCellFrame: NSRect?
    
    var selectedComponent: SubTitleTimeIntervalCell?
    
    var mouseInTheArea: Bool = false
    
    var intervalTimeString: String {
        get {
            return "\(self.hoursCell!.stringValue):\(self.minutesCell!.stringValue):\(self.secondsCell!.stringValue),\(self.millisecondsCell!.stringValue)"
        }
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setUpCells()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUpCells()
    }
    
    func setUpCells() {
        self.hoursCell = setupTimeIntervalCell("00", alignment: .Right, size: NSSize(width: 19, height: 15), max: 24, formatString: "%02d", limit: 10)
        self.minutesCell = setupTimeIntervalCell("00", alignment: .Right, size: NSSize(width: 19, height: 15), max: 60, formatString: "%02d", limit: 10)
        self.secondsCell = setupTimeIntervalCell("00", alignment: .Right, size: NSSize(width: 19, height: 15), max: 60, formatString: "%02d", limit: 10)
        self.millisecondsCell = setupTimeIntervalCell("000", alignment: .Right, size: NSSize(width: 27, height: 15), max: 999, formatString: "%03d", limit: 100)
        
        self.hoursCell!.setNeighbors(nil, right: self.minutesCell)
        self.minutesCell!.setNeighbors(self.hoursCell, right: self.secondsCell)
        self.secondsCell!.setNeighbors(self.minutesCell, right: self.millisecondsCell)
        self.millisecondsCell!.setNeighbors(self.secondsCell, right: nil)
        
        self.separatorCell1 = self.setupTimeIntervalCell(":", alignment: .Left, size: NSSize(width: 5, height: 15))
        self.separatorCell2 = self.setupTimeIntervalCell(":", alignment: .Left, size: NSSize(width: 5, height: 15))
        self.separatorCell3 = self.setupTimeIntervalCell(",", alignment: .Left, size: NSSize(width: 5, height: 15))
        
        self.stepperCell = NSStepperCell()
    }
    
    override func awakeFromNib() {
        let trackingArea = NSTrackingArea.init(rect: self.bounds, options: [NSTrackingAreaOptions.MouseEnteredAndExited, NSTrackingAreaOptions.ActiveAlways], owner: self, userInfo: nil)
        
        self.addTrackingArea(trackingArea)
    }
    
    func setupTimeIntervalCell(string: String, alignment: NSTextAlignment, size: NSSize, max: Int = 0, formatString: String? = nil, limit: Int = 0) -> SubTitleTimeIntervalCell {
        let cell: SubTitleTimeIntervalCell = SubTitleTimeIntervalCell(textCell: string, size: size, max: max, formatString: formatString, limit: limit)
        cell.drawsBackground = true
        cell.backgroundColor = NSColor.whiteColor()
        cell.editable = true
        cell.bordered = false
        cell.font = NSFont.controlContentFontOfSize(NSFont.systemFontSizeForControlSize(.SmallControlSize))
        cell.alignment = alignment
        return cell
    }
    
    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)
        //Swift.print("drawRect")
        
        // Draw Control Frame
        var controlFrame: NSRect = self.bounds
        controlFrame.size.width -= self.stepperCell!.cellSize.width - 2.0
        
        NSColor.whiteColor().setFill()
        NSBezierPath(roundedRect: controlFrame, xRadius: 5.0, yRadius: 5.0).fill()
        
        // Draw Cells Frame
        var cellFrame: NSRect = self.bounds
        
        // stepper cell
        cellFrame.size = self.stepperCell!.cellSize
        cellFrame.origin.x = NSMaxX(self.bounds) - cellFrame.size.width + 1.0
        cellFrame.origin.y -= 1.0
        self.stepperCellFrame = cellFrame
        self.stepperCell!.drawWithFrame(self.stepperCellFrame!, inView: self)
        
        cellFrame = NSInsetRect(self.bounds, 2.0, 3.0)
        
        // hours cell
        cellFrame.size = self.hoursCell!.size!
        self.hoursCell!.drawWithFrame(cellFrame, inView: self)
        
        // separator1
        cellFrame.origin.x += cellFrame.size.width
        cellFrame.size = self.separatorCell1!.size!
        self.separatorCell1!.drawWithFrame(cellFrame, inView: self)
        
        // minutes cell
        cellFrame.origin.x += cellFrame.size.width
        cellFrame.size = self.minutesCell!.size!
        self.minutesCell!.drawWithFrame(cellFrame, inView: self)
        
        // separator2
        cellFrame.origin.x += cellFrame.size.width
        cellFrame.size = self.separatorCell2!.size!
        self.separatorCell2!.drawWithFrame(cellFrame, inView: self)
        
        // seconds cell
        cellFrame.origin.x += cellFrame.size.width
        cellFrame.size = self.secondsCell!.size!
        self.secondsCell!.drawWithFrame(cellFrame, inView: self)
        
        // separator3
        cellFrame.origin.x += cellFrame.size.width
        cellFrame.size = self.separatorCell3!.size!
        self.separatorCell3!.drawWithFrame(cellFrame, inView: self)
        
        // milliseconds cell
        cellFrame.origin.x += cellFrame.size.width
        cellFrame.size = self.millisecondsCell!.size!
        self.millisecondsCell!.drawWithFrame(cellFrame, inView: self)
    }
    
    override func mouseDown(theEvent: NSEvent) {
        super.mouseDown(theEvent)
        
        //Swift.print("mouseDown")
        
        if !self.mouseInTheArea {
            return
        }
        
        let locationInControlFrame: NSPoint = self.convertPoint(theEvent.locationInWindow, fromView: nil)
        
        if NSMouseInRect(locationInControlFrame, self.stepperCellFrame!, self.flipped) {
            self.stepperCell!.trackMouse(theEvent, inRect: self.bounds, ofView: self, untilMouseUp: true)
            
            guard let currentEditor = self.currentEditor() else {
                selectComponent(self.secondsCell!)
                return
            }
            
            let stepperValue: Int = self.stepperCell!.integerValue
            self.selectedComponent!.integerValue = stepperValue
            currentEditor.string = self.selectedComponent!.stringValue
            
        } else if NSMouseInRect(locationInControlFrame, self.hoursCell!.frame!, self.flipped) {
            selectComponent(self.hoursCell!)
        } else if NSMouseInRect(locationInControlFrame, self.minutesCell!.frame!, self.flipped) {
            selectComponent(self.minutesCell!)
        } else if NSMouseInRect(locationInControlFrame, self.secondsCell!.frame!, self.flipped) {
            selectComponent(self.secondsCell!)
        } else if NSMouseInRect(locationInControlFrame, self.millisecondsCell!.frame!, self.flipped) {
            selectComponent(self.millisecondsCell!)
        }
    }
    
    func selectComponent(cell: SubTitleTimeIntervalCell) {
        if let selectedComponent = self.selectedComponent {
            selectedComponent.endEditing(self.currentEditor()!)
        }
        
        self.selectedComponent = cell
        
        let fieldEditor: NSText! = self.window!.fieldEditor(true, forObject: cell)
        let length = fieldEditor.string!.characters.count
        cell.selectWithFrame(cell.frame!, inView: self, editor: fieldEditor, delegate: self, start: 0, length: length)
        
        updateStepper(cell.max!, min: 0, value: cell.stringValue)
    }
    
    func textView(textView: NSTextView, shouldChangeTextInRange affectedCharRange: NSRange, replacementString: String?) -> Bool {
        
        if let _ = replacementString!.rangeOfCharacterFromSet(NSCharacterSet.decimalDigitCharacterSet().invertedSet) {
            //Swift.print("not number")
            return false
        }
        
        guard let currentEditor = self.currentEditor() else {
            return false
        }
        
        //Swift.print("replacementString : \(replacementString)")
        
        let addedValue: Int = Int(replacementString!)!
        let currentValue = self.selectedComponent!.updateValue(addedValue)
        
        currentEditor.string = currentValue
        updateStepper(self.selectedComponent!.max!, min: 0, value: currentValue)
        
        return false
    }
    
    func textView(textView: NSTextView, willChangeSelectionFromCharacterRange oldSelectedCharRange: NSRange, toCharacterRange newSelectedCharRange: NSRange) -> NSRange {
        //Swift.print("willChangeSelectionFromCharacterRange : \(textView.string!.characters.count)")
        
        return NSMakeRange(0, textView.string!.characters.count)
    }
    
    func textView(textView: NSTextView, doCommandBySelector commandSelector: Selector) -> Bool {
        //Swift.print(commandSelector.description)
        
        if commandSelector.description == "moveLeft:" {
            if let selectedComponent = self.selectedComponent {
                if let left = selectedComponent.left {
                    selectComponent(left)
                }
            }
            
        } else if commandSelector.description == "moveRight:" {
            if let selectedComponent = self.selectedComponent {
                if let right = selectedComponent.right {
                    selectComponent(right)
                }
            }
            
        }
        
        return true
    }
    
    override func mouseEntered(theEvent: NSEvent) {
        super.mouseEntered(theEvent)
        //Swift.print("mouseEntered")
        self.mouseInTheArea = true
        
    }
    
    override func mouseExited(theEvent: NSEvent) {
        super.mouseExited(theEvent)
        //Swift.print("mouseExited")
        self.mouseInTheArea = false
    }
    
    func textDidEndEditing(notification: NSNotification) {
        //Swift.print("textDidEndEditing")
        
        if !self.mouseInTheArea {
            //Swift.print("Lost Focus")
            if let selectedComponent = self.selectedComponent {
                selectedComponent.endEditing(self.currentEditor()!)
                self.selectedComponent = nil
            }
        }
    }
    
    func updateStepper(max: Int, min: Int, value: String) {
        self.stepperCell!.maxValue = Double(max)
        self.stepperCell!.minValue = Double(min)
        self.stepperCell!.stringValue = value
    }
}
