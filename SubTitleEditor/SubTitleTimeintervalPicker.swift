//
//  SubTitleTimeintervalPicker.swift
//  SubTitleEditor
//
//  Created by 장기현 on 2016. 1. 30..
//  Copyright © 2016년 JKH. All rights reserved.
//

import Cocoa

class SubTitleTimeIntervalCell {
    let cell: NSTextFieldCell
    let size: NSSize
    let max: Int
    let formatString: String
    let limit: Int
    
    var right: SubTitleTimeIntervalCell?
    var left: SubTitleTimeIntervalCell?
    
    var frame: NSRect?
    
    var integerValue: Int = 0 {
        didSet {
            self.cell.stringValue = String(format: self.formatString, integerValue)
        }
    }
    
    var stringValue: String {
        get {
            return self.cell.stringValue
        }
    }
    
    init(cell: NSTextFieldCell, size: NSSize, max: Int, formatString: String, limit: Int) {
        self.cell = cell
        self.size = size
        self.max = max
        self.formatString = formatString
        self.limit = limit
    }
    
    func drawWithFrame(controlView: NSView) {
        self.cell.drawWithFrame(frame!, inView: controlView)
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
    var hoursComponent: SubTitleTimeIntervalCell?
    var minutesComponent: SubTitleTimeIntervalCell?
    var secondsComponent: SubTitleTimeIntervalCell?
    var millisecondsComponent: SubTitleTimeIntervalCell?
    
    var separatorCell1: NSTextFieldCell?
    var separatorCellFrame1: NSRect?
    
    var separatorCell2: NSTextFieldCell?
    var separatorCellFrame2: NSRect?
    
    var separatorCell3: NSTextFieldCell?
    var separatorCellFrame3: NSRect?
    
    let separatorCellSize: NSSize = NSSize(width: 6, height: 17)
    
    var stepperCell: NSStepperCell?
    var stepperCellFrame: NSRect?
    
    var selectedComponent: SubTitleTimeIntervalCell?
    
    var mouseInTheArea: Bool = false
    
    var intervalTimeString: String {
        get {
            return "\(self.hoursComponent!.stringValue):\(self.minutesComponent!.stringValue):\(self.secondsComponent!.stringValue),\(self.millisecondsComponent!.stringValue)"
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
        self.hoursComponent = SubTitleTimeIntervalCell(cell: self.setupCellWithString("00", alignment: .Right), size: NSSize(width: 21, height: 17), max: 24, formatString: "%02d", limit: 10)
        self.minutesComponent = SubTitleTimeIntervalCell(cell: self.setupCellWithString("00", alignment: .Right), size: NSSize(width: 21, height: 17), max: 60, formatString: "%02d", limit: 10)
        self.secondsComponent = SubTitleTimeIntervalCell(cell: self.setupCellWithString("00", alignment: .Right), size: NSSize(width: 21, height: 17), max: 60, formatString: "%02d", limit: 10)
        self.millisecondsComponent = SubTitleTimeIntervalCell(cell: self.setupCellWithString("000", alignment: .Right), size: NSSize(width: 29, height: 17), max: 999, formatString: "%03d", limit: 100)
        
        self.hoursComponent!.setNeighbors(nil, right: self.minutesComponent)
        self.minutesComponent!.setNeighbors(self.hoursComponent, right: self.secondsComponent)
        self.secondsComponent!.setNeighbors(self.minutesComponent, right: self.millisecondsComponent)
        self.millisecondsComponent!.setNeighbors(self.secondsComponent, right: nil)
        
        self.separatorCell1 = self.setupCellWithString(":", alignment: .Left)
        self.separatorCell2 = self.setupCellWithString(":", alignment: .Left)
        self.separatorCell3 = self.setupCellWithString(",", alignment: .Left)
        
        self.stepperCell = NSStepperCell()
    }
    
    override func awakeFromNib() {
        let trackingArea = NSTrackingArea.init(rect: self.bounds, options: [NSTrackingAreaOptions.MouseEnteredAndExited, NSTrackingAreaOptions.ActiveAlways], owner: self, userInfo: nil)
        
        self.addTrackingArea(trackingArea)
    }
    
    func setupCellWithString(string: String, alignment: NSTextAlignment) -> NSTextFieldCell {
        let cell: NSTextFieldCell = NSTextFieldCell(textCell: string)
        cell.drawsBackground = true
        cell.editable = true
        cell.bordered = false
        cell.controlSize = self.controlSize
        cell.font = NSFont.controlContentFontOfSize(NSFont.systemFontSizeForControlSize(self.controlSize))
        cell.alignment = alignment
        return cell
    }
    
    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)
        //Swift.print("drawRect")
        
        // Draw Control Frame
        var borderFrame: NSRect = self.bounds
        borderFrame.size.width -= self.stepperCell!.cellSize.width - 1.0
        let sides: [NSRectEdge] = [.MaxY, .MaxX, .MinX, .MinY, .MaxY]
        let enabledGrays: [CGFloat] = [0.75, 0.75, 0.75, 0.75]
        let disabledGrays: [CGFloat] = [0.85, 0.85, 0.85, 0.85]
        
        if self.enabled {
            borderFrame = NSDrawTiledRects(borderFrame, borderFrame, sides, enabledGrays, 4)
        } else {
            borderFrame = NSDrawTiledRects(borderFrame, borderFrame, sides, disabledGrays, 4)
        }
        
        NSColor.whiteColor().set()
        NSRectFill(borderFrame)
        
        // Draw Cells Frame
        let baseFrame: NSRect = self.bounds
        var frame: NSRect = baseFrame
        
        // stepper cell
        frame.size = self.stepperCell!.cellSize
        frame.origin.x = NSMaxX(baseFrame) - frame.size.width + 1.0
        frame.origin.y -= 1.0
        self.stepperCellFrame = frame
        self.stepperCell!.drawWithFrame(self.stepperCellFrame!, inView: self)
        
        frame = NSInsetRect(baseFrame, 2.0, 2.0)
        
        // hours cell
        frame.size = self.hoursComponent!.size
        
        self.hoursComponent!.frame = frame
        self.hoursComponent!.drawWithFrame(self)
        
        // separator1
        frame.origin.x += frame.size.width
        frame.size = separatorCellSize
        
        self.separatorCellFrame1 = frame
        self.separatorCell1!.drawWithFrame(self.separatorCellFrame1!, inView: self)
        
        // minutes cell
        frame.origin.x += frame.size.width
        frame.size = self.minutesComponent!.size
        
        self.minutesComponent!.frame = frame
        self.minutesComponent!.drawWithFrame(self)
        
        // separator2
        frame.origin.x += frame.size.width
        frame.size = separatorCellSize
        
        self.separatorCellFrame2 = frame
        self.separatorCell2!.drawWithFrame(self.separatorCellFrame2!, inView: self)
        
        // seconds cell
        frame.origin.x += frame.size.width
        frame.size = self.secondsComponent!.size
        
        self.secondsComponent!.frame = frame
        self.secondsComponent!.drawWithFrame(self)
        
        // separator3
        frame.origin.x += frame.size.width
        frame.size = separatorCellSize
        
        self.separatorCellFrame3 = frame
        self.separatorCell3!.drawWithFrame(self.separatorCellFrame3!, inView: self)
        
        // milliseconds cell
        frame.origin.x += frame.size.width
        frame.size = self.millisecondsComponent!.size
        
        self.millisecondsComponent!.frame = frame
        self.millisecondsComponent!.drawWithFrame(self)
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
                selectComponent(self.secondsComponent!)
                return
            }
            
            let stepperValue: Int = self.stepperCell!.integerValue
            self.selectedComponent!.integerValue = stepperValue
            currentEditor.string = self.selectedComponent!.stringValue
            
        } else if NSMouseInRect(locationInControlFrame, self.hoursComponent!.frame!, self.flipped) {
            selectComponent(self.hoursComponent!)
        } else if NSMouseInRect(locationInControlFrame, self.minutesComponent!.frame!, self.flipped) {
            selectComponent(self.minutesComponent!)
        } else if NSMouseInRect(locationInControlFrame, self.secondsComponent!.frame!, self.flipped) {
            selectComponent(self.secondsComponent!)
        } else if NSMouseInRect(locationInControlFrame, self.millisecondsComponent!.frame!, self.flipped) {
            selectComponent(self.millisecondsComponent!)
        }
    }
    
    func selectComponent(component: SubTitleTimeIntervalCell) {
        if let selectedComponent = self.selectedComponent {
            selectedComponent.cell.endEditing(self.currentEditor()!)
        }
        
        self.selectedComponent = component
        
        let fieldEditor: NSText! = self.window!.fieldEditor(true, forObject: component.cell)
        let length = fieldEditor.string!.characters.count
        component.cell.selectWithFrame(component.frame!, inView: self, editor: fieldEditor, delegate: self, start: 0, length: length)
        
        updateStepper(component.max, min: 0, value: component.cell.stringValue)
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
        updateStepper(self.selectedComponent!.max, min: 0, value: currentValue)
        
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
            if let component = self.selectedComponent {
                component.cell.endEditing(self.currentEditor()!)
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