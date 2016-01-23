//
//  ViewController.swift
//  SubTitleEditor
//
//  Created by 장기현 on 2015. 12. 15..
//  Copyright © 2015년 JKH. All rights reserved.
//

import Cocoa

class OnlyAllowNumberFormatter : NSNumberFormatter {
    override func isPartialStringValid(partialString: String, newEditingString newString: AutoreleasingUnsafeMutablePointer<NSString?>, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>) -> Bool {
        
        if let _ = partialString.rangeOfCharacterFromSet(NSCharacterSet.decimalDigitCharacterSet().invertedSet) {
            return false
        }
        
        return true
        
    }
}

class ViewController: NSViewController {

    @IBOutlet weak var intervalDisplay: NSButton!
    @IBOutlet weak var intervalInput: NSTextField!
    @IBOutlet var output: NSTextView!
    @IBOutlet weak var tableView: NSTableView!
    
    var subTitleDoc: SubTitleDoc?
    
    //var subTitleItemsForSearch: [SubTitleData]?
    var subTitleItemsToShow: [SubTitleData]?
    var subTitleItemsRaw: [SubTitleData]?
    
    let subTitle: String = "subTitle"
    
    var applyAllRows: Bool = true
    var intervalTimeAmount: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        tableView.registerForDraggedTypes([subTitle, NSURLPboardType])
        
        self.intervalDisplay.title = "00:00:00,000"
        
        let formatter: OnlyAllowNumberFormatter = OnlyAllowNumberFormatter()
        self.intervalInput.formatter = formatter
    }

    override var representedObject: AnyObject? {
        didSet {
            if let url = representedObject as? NSURL {
                print("opening file : \(url.path!)")
                
                output.logging(url.path!)
                
                undoManager?.removeAllActions()
                
                subTitleDoc = SubTitleDocFactory.Create(url)
                reloadSubTitleData()
            }
        }
    }
    
    func isTableInSearchMode() -> Bool {
        return self.subTitleItemsRaw != nil
    }
    
    func reloadSubTitleData() {
        do {
            subTitleItemsToShow = try subTitleDoc?.parse()
            tableView.reloadData()
        } catch SubTitleError.ParseError(let message) {
            output.logging(message, color: NSColor.redColor())
        } catch SubTitleError.InvalidURLPath {
            output.logging("Invalid URL Path", color: NSColor.redColor())
        } catch SubTitleError.StreamOpenError {
            output.logging("Stream Open Error", color: NSColor.redColor())
        } catch {
            output.logging("something goes wrong", color: NSColor.redColor())
        }
    }
    
    func addItems(rows: NSIndexSet, items: AnyObject) {
        //print("addItems")
        
        let data = items as! [SubTitleData]
        var i: Int = 0
        var firstIndex: Int = -1
        rows.enumerateIndexesUsingBlock {
            (index: Int, stop) -> Void in
            
            let item = data[i++]
            //print("\(item.num) : \(item.text)")

            self.subTitleItemsToShow?.insert(item, atIndex: index)
            
            if self.isTableInSearchMode() {
                self.subTitleItemsRaw?.insert(item, atIndex: item.num)
                if firstIndex == -1 {
                    firstIndex = item.num
                }
            }
        }
        
        //To re-ordering data num when add
        if self.isTableInSearchMode() {
            var count = firstIndex
            for item in self.subTitleItemsRaw![firstIndex+1..<self.subTitleItemsRaw!.count] {
                item.num = ++count
            }
        }
        
        self.tableView.reloadData()
        
        undoManager?.prepareWithInvocationTarget(self).removeItems(rows)
        undoManager?.setActionName(NSLocalizedString("actions.add", comment: "Add Items"))
    }
    
    func removeItems(rows: NSIndexSet) {
        //print("removeItems")
        
        var items: [SubTitleData] = [SubTitleData]()
        
        var firstIndex: Int = -1
        rows.enumerateIndexesWithOptions(.Reverse) {
            (index: Int, _) -> Void in
            
            let datum: SubTitleData! = self.subTitleItemsToShow?.removeAtIndex(index)
            //print("\(datum.num) : \(datum.text)")
            items.append(datum)
            
            if self.isTableInSearchMode() {
                self.subTitleItemsRaw?.removeAtIndex(datum.num)
                //print("\(datum.num) : \(datum.text)")
                firstIndex = datum.num
            }
        }
        
        //To re-ordering data num when remove
        if self.isTableInSearchMode() {
            var count = firstIndex
            for item in self.subTitleItemsRaw![firstIndex..<self.subTitleItemsRaw!.count] {
                item.num = count++
            }
        }
        
        self.tableView.reloadData()
        
        undoManager?.prepareWithInvocationTarget(self).addItems(rows, items: items.reverse())
        undoManager?.setActionName(NSLocalizedString("actions.remove", comment: "Remove Items"))
    }
}

extension ViewController: NSTableViewDataSource {
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return self.subTitleItemsToShow?.count ?? 0
    }
    
    func tableView(tableView: NSTableView, writeRowsWithIndexes: NSIndexSet, toPasteboard: NSPasteboard) -> Bool {
        //print("writeRowsWithIndexes")
        
        let data = NSKeyedArchiver.archivedDataWithRootObject([writeRowsWithIndexes])
        toPasteboard.declareTypes([subTitle], owner:self)
        toPasteboard.setData(data, forType:subTitle)
        
        return true
    }
    
    func tableView(tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableViewDropOperation) -> NSDragOperation
    {
        //print("validateDrop")
        
        if dropOperation == .On {
            return .None
        }
        
        //get the file URLs from the pasteboard
        let pb: NSPasteboard = info.draggingPasteboard()
        
        if let _ = pb.dataForType(subTitle) {
            if !self.isTableInSearchMode() {
                tableView.setDropRow(row, dropOperation: NSTableViewDropOperation.Above)
                return .Move
            }
        } else {
            guard let url = NSURL(fromPasteboard: pb) else {
                return .None
            }
            
            //only file allow
            var isDirectory = ObjCBool(false)
            if NSFileManager.defaultManager().fileExistsAtPath(url.path!, isDirectory: &isDirectory) {
                if !isDirectory {
                    
                    //only srt file allow
                    guard let ext = url.pathExtension else {
                        return .None
                    }
                    
                    //print(ext)
                    if ext == "srt" || ext == "smi" {
                        return .Every
                    }
                }
            }
        }
        
        return .None
    }
    
    func tableView(tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int,
        dropOperation: NSTableViewDropOperation) -> Bool
    {
        //print("acceptDrop")
        
        let pb = info.draggingPasteboard()
        
        if let data = pb.dataForType(subTitle) {
            let dataArray: [NSIndexSet]  = NSKeyedUnarchiver.unarchiveObjectWithData(data) as! [NSIndexSet]
            let indexSet = dataArray[0]
            let currentRow  = indexSet.firstIndex
            print("move \(currentRow) --> \(row)")
            
            let item = self.subTitleItemsToShow![currentRow]
            print(item.text)
            
            if currentRow < row {
                //move down
                print("move down")
                
                /* in case of moving down
                 * 1. insert first
                 * 2. then remove
                */
                
                //insert moving item
                subTitleItemsToShow!.insert(item, atIndex: row)
                //tableView.insertRowsAtIndexes(NSIndexSet(index: row), withAnimation: .SlideLeft)
                
                //remove previous item
                subTitleItemsToShow!.removeAtIndex(currentRow)
                //tableView.removeRowsAtIndexes(NSIndexSet(index: currentRow), withAnimation: .EffectFade)
                
                tableView.reloadData()
                
                return true
                
            } else if currentRow > row {
                //move up
                print("move up")
                
                /* in case of moving up
                 * 1. remove first
                 * 2. then insert
                */
                
                //remove item
                subTitleItemsToShow!.removeAtIndex(currentRow)
                //tableView.removeRowsAtIndexes(NSIndexSet(index: currentRow), withAnimation: .EffectFade)
                
                //insert moving item
                subTitleItemsToShow!.insert(item, atIndex: row)
                //tableView.insertRowsAtIndexes(NSIndexSet(index: row), withAnimation: .SlideRight)
                
                tableView.reloadData()
                
                return true
            }
            
        } else if let url = NSURL(fromPasteboard: pb) {
            self.representedObject = url
            return true
        }
        
        return false
    }
}

extension ViewController: NSTableViewDelegate {
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        var text: String = ""
        var cellIdentifier: String = ""
        
        guard let item = self.subTitleItemsToShow?[row] else {
            return nil
        }
        
        if tableColumn == tableView.tableColumns[0] {
            if self.isTableInSearchMode() {
                //the items in searching
                text = String(item.num + 1)
            } else {
                //not the items in searching
                item.num = row
                text = String(row + 1)
            }
            cellIdentifier = "eNumber"
        } else if tableColumn == tableView.tableColumns[1] {
            text = item.start
            cellIdentifier = "eStart"
        } else if tableColumn == tableView.tableColumns[2] {
            text = item.end
            cellIdentifier = "eEnd"
        } else if tableColumn == tableView.tableColumns[3] {
            text = item.duration
            cellIdentifier = "eDuration"
        } else if tableColumn == tableView.tableColumns[4] {
            text = item.text
            cellIdentifier = "eText"
        }
        
        if let cell = tableView.makeViewWithIdentifier(cellIdentifier, owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = text
            return cell
        }
        
        return nil
    }
}

extension ViewController {
    @IBAction func clearTable(sender: AnyObject) {
        self.subTitleItemsToShow?.removeAll()
        self.tableView.reloadData()
        
        undoManager?.removeAllActions()
    }
    
    @IBAction func onEnterInSearchField(sender: AnyObject) {
        print("onEnterInSearchField")
        
        print("number of rows : \(self.tableView.numberOfRows)")
        //To prevent exception when no subtitle is loaded. (initial state)
        if self.subTitleItemsToShow == nil {
            return
        }
        
        if let textField = sender as? NSTextField {
            let searchText = textField.stringValue
            print("textField : \(textField.stringValue)")
            
            if searchText.isEmpty {
                if self.subTitleItemsRaw != nil {
                    print("reload all")
                    self.subTitleItemsToShow = self.subTitleItemsRaw
                    self.subTitleItemsRaw = nil
                    undoManager?.removeAllActions()
                    self.tableView.reloadData()
                }
            } else {
                if self.subTitleItemsRaw == nil {
                    self.subTitleItemsRaw = self.subTitleItemsToShow
                }
                
                self.subTitleItemsToShow?.removeAll(keepCapacity: false)
                
                for item in self.subTitleItemsRaw! {
                    if item.text.containsString(searchText) {
                        self.subTitleItemsToShow?.append(item)
                    }
                }
                
                self.tableView.reloadData()
            }
        }
    }

    @IBAction func onEnterInTextField(sender: NSTextField) {
        print("onEnterInTextField")
        
        let selectedRow = self.tableView.selectedRow
        if selectedRow != -1 {
            let item: SubTitleData! = self.subTitleItemsToShow?[selectedRow]
            print("\(item.num) : \(item.text)")
            item.text = sender.stringValue
            self.tableView.reloadData()
        }
    }
    
    @IBAction func saveDocument(sender: AnyObject) {
        guard let subTitleItems = subTitleItemsToShow where subTitleItems.count != 0 else {
            return
        }
        
        let url = self.subTitleDoc!.url
        let filePath = url.URLByDeletingPathExtension!.path! + ".srt"
        
        output.logging("save file path : \(filePath)\n")
        print("save file path : \(filePath)")
        
        //create empty file
        let fileManager = NSFileManager.defaultManager().createFileAtPath(filePath, contents: nil, attributes: nil)
        
        //wirte data to file with utf-8
        if let fileHandle = NSFileHandle(forWritingAtPath: filePath) {
            defer {
                print("call closeFile")
                fileHandle.closeFile()
            }
            
            for num in 0..<subTitleItems.count {
                let datum = subTitleItems[num]
                let subTitleText = datum.text.stringByReplacingOccurrencesOfString("<br>", withString: "\n", options: .CaseInsensitiveSearch)
                
                let no = "\(num+1)\n\(datum.start) --> \(datum.end)\n\(subTitleText)\n\n"
                if let dataToWrite = no.dataUsingEncoding(NSUTF8StringEncoding) {
                    fileHandle.writeData(dataToWrite)
                }
            }
        }
    }
    
    @IBAction func openDocument(sender: AnyObject) {
        let openPanel = NSOpenPanel()
        openPanel.showsHiddenFiles      = false
        openPanel.canChooseFiles        = true
        openPanel.canChooseDirectories  = false
        
        openPanel.beginSheetModalForWindow(self.view.window!) {
            (response) -> Void in
            guard response == NSFileHandlingPanelOKButton else {
                return;
            }
            self.representedObject = openPanel.URL
        }
    }
    
    @IBAction func removeLine(sender: AnyObject) {
        //print("removeLine")
        let rows = self.tableView.selectedRowIndexes
        self.removeItems(rows)
    }
    
    enum ChangeType {
        case Pull
        case Push
    }
    
    func changeIntervalInRange(items: [SubTitleData], type: ChangeType) {
        for item in items {
            let sTime = SubTitleTime(timeInStr: item.start)
            let eTime = SubTitleTime(timeInStr: item.end)
            
            let timeChange: (start: SubTitleTime, end: SubTitleTime) = (type == .Pull) ? (sTime - self.intervalTimeAmount, eTime - self.intervalTimeAmount) : (sTime + self.intervalTimeAmount, eTime + self.intervalTimeAmount)
            
            item.start = timeChange.start.getReadableTime()
            item.end = timeChange.end.getReadableTime()
        }
    }
    
    @IBAction func pullTiming(sender: AnyObject) {
        //print("pullTiming")
        if self.applyAllRows {
            changeIntervalInRange(self.subTitleItemsToShow!, type: .Pull)
            
            self.tableView.reloadData()
        } else {
            let selectedRow = self.tableView.selectedRow
            if selectedRow != -1 {
                let lastRow = self.subTitleItemsToShow!.count - 1
                let items = Array(self.subTitleItemsToShow![selectedRow...lastRow])
                changeIntervalInRange(items, type: .Pull)
                
                self.tableView.reloadData()
                self.tableView.selectRowIndexes(NSIndexSet(index: selectedRow), byExtendingSelection: false)
            }
        }
    }
    
    @IBAction func pushTiming(sender: AnyObject) {
        //print("pushTiming")
        if self.applyAllRows {
            changeIntervalInRange(self.subTitleItemsToShow!, type: .Push)
            
            self.tableView.reloadData()
        } else {
            let selectedRow = self.tableView.selectedRow
            if selectedRow != -1 {
                let lastRow = self.subTitleItemsToShow!.count - 1
                let items = Array(self.subTitleItemsToShow![selectedRow...lastRow])
                changeIntervalInRange(items, type: .Push)
                
                self.tableView.reloadData()
                self.tableView.selectRowIndexes(NSIndexSet(index: selectedRow), byExtendingSelection: false)
            }
        }
    }
    
    @IBAction func onConvertReadableTime(sender: AnyObject) {
        if let milliseconds = Int(self.intervalInput.stringValue) {
            self.intervalTimeAmount = milliseconds
            
            let subTitleTime = SubTitleTime(milliseconds: milliseconds)
            self.intervalDisplay.title = subTitleTime.getReadableTime()
            
            self.intervalInput.stringValue = ""
        }
    }
    
    @IBAction func checkApplyRange(sender: NSButton) {
        print("checkApplyRange")
        
        if sender.identifier == "fromFirstRow" {
            print("From the first row")
            self.applyAllRows = true
        } else if sender.identifier == "fromSelectedRow" {
            print("From the selected row")
            self.applyAllRows = false
        }
    }
}

extension NSTextView {
    func logging(line: String, color: NSColor = NSColor.blackColor()) {
        //set font and color
        let attriDict = [NSFontAttributeName: NSFont.systemFontOfSize(12.0),
            NSForegroundColorAttributeName: color]
        
        let attrString = NSAttributedString(string: "\(line)\n", attributes: attriDict)
        self.textStorage?.appendAttributedString(attrString)
        
        //locate cursor at the front of next line so autoscroll
        if let loc = self.string?.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) {
            self.scrollRangeToVisible(NSRange(location: loc, length: 0))
        }
    }
}

extension ViewController: NSMenuDelegate {
    func menuNeedsUpdate(menu: NSMenu) {
        menu.autoenablesItems = false
        let mItems: [NSMenuItem] = menu.itemArray
        let mItemEnable: Bool = (tableView.clickedRow == -1) ? false : true
        
        for item in mItems {
            item.enabled = mItemEnable
        }
        
    }
}