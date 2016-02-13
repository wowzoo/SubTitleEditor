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

    @IBOutlet weak var timePicker: SubTitleTimeintervalPicker!
    @IBOutlet weak var extLabel: NSTextField!
    @IBOutlet weak var outputLabel: NSTextField!
    
    @IBOutlet weak var tableView: NSTableView!
    
    var subTitleDoc: SubTitleDoc?
    
    var subTitleItemsToShow: [SubTitleData]?
    var subTitleItemsRaw: [SubTitleData]?
    
    let subTitle: String = "subTitle"
    
    //var applyAllRows: Bool = true
    var intervalTimeAmount: Int = 0
    
    var fileNameIncrement: Int = 1
    
    enum ChangeType {
        case Pull
        case Push
    }
    
    enum ChangeRange {
        case All
        case FromSelectedToEnd
        case OnlySelected
        case None
    }
    
    var changeRange: ChangeRange = .All
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        tableView.registerForDraggedTypes([subTitle, NSURLPboardType])
        //timePicker.enabled = true
    }
    
    override var representedObject: AnyObject? {
        didSet {
            if let url = representedObject as? NSURL {
                subTitleDoc = SubTitleDocFactory.Create(url)
                reloadSubTitleData()
            }
        }
    }
    
    func isTableInSearchMode() -> Bool {
        return self.subTitleItemsRaw != nil
    }
    
    func resetAll() {
        self.subTitleItemsToShow?.removeAll()
        self.tableView.reloadData()
        
        undoManager?.removeAllActions()
        
        self.intervalTimeAmount = 0
        self.fileNameIncrement = 1
    }
    
    func reloadSubTitleData() {
        self.resetAll()
        
        self.view.window?.title = subTitleDoc!.fileName
        self.extLabel.stringValue = subTitleDoc!.fileExtension
        
        do {
            subTitleItemsToShow = try subTitleDoc?.parse()
            self.outputLabel.stringValue = "Encoding : \(subTitleDoc!.encoding)"
            self.tableView.reloadData()
            self.tableView.scrollRowToVisible(0)
            
//            let alert = NSAlert()
//            alert.messageText = "Warning"
//            alert.addButtonWithTitle("OK")
//            alert.informativeText = "There are problems, please resolve these first"
//            
//            alert.beginSheetModalForWindow(self.view.window!, completionHandler: nil)

            
        } catch SubTitleError.ParseError(let message) {
            self.outputLabel.stringValue = "Error : \(message)"
        } catch SubTitleError.InvalidURLPath {
            self.outputLabel.stringValue = "Error : Invalid URL Path"
        } catch SubTitleError.StreamOpenError {
            self.outputLabel.stringValue = "Error : Stream Open Failed"
        } catch {
            self.outputLabel.stringValue = "Error : Unknown, Something goes wrong"
        }
    }
    
    func addItems(rows: NSIndexSet, items: AnyObject) {
        let data = items as! [SubTitleData]
        var i: Int = 0
        var firstIndex: Int = -1
        rows.enumerateIndexesUsingBlock {
            (index: Int, stop) -> Void in
            
            let item = data[i++]

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
        var items: [SubTitleData] = [SubTitleData]()
        
        var firstIndex: Int = -1
        rows.enumerateIndexesWithOptions(.Reverse) {
            (index: Int, _) -> Void in
            
            let datum: SubTitleData! = self.subTitleItemsToShow?.removeAtIndex(index)
            items.append(datum)
            
            if self.isTableInSearchMode() {
                self.subTitleItemsRaw?.removeAtIndex(datum.num)
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
        let data = NSKeyedArchiver.archivedDataWithRootObject([writeRowsWithIndexes])
        toPasteboard.declareTypes([subTitle], owner:self)
        toPasteboard.setData(data, forType:subTitle)
        
        return true
    }
    
    func tableView(tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableViewDropOperation) -> NSDragOperation
    {
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
        let pb = info.draggingPasteboard()
        
        if let data = pb.dataForType(subTitle) {
            let dataArray: [NSIndexSet]  = NSKeyedUnarchiver.unarchiveObjectWithData(data) as! [NSIndexSet]
            let indexSet = dataArray[0]
            let currentRow  = indexSet.firstIndex
            
            let item = self.subTitleItemsToShow![currentRow]
            
            if currentRow < row {
                //move down
                
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
        self.resetAll()
        
        self.view.window?.title = "SubTitleEditor"
        self.extLabel.stringValue = ""
        self.outputLabel.stringValue = ""
    }
    
    @IBAction func onEnterInSearchField(sender: AnyObject) {
        //To prevent exception when no subtitle is loaded. (initial state)
        if self.subTitleItemsToShow == nil {
            return
        }
        
        if let textField = sender as? NSTextField {
            let searchText = textField.stringValue
            //print("textField : \(textField.stringValue)")
            
            if searchText.isEmpty {
                if self.subTitleItemsRaw != nil {
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
        let selectedRow = self.tableView.selectedRow
        if selectedRow != -1 {
            let item: SubTitleData! = self.subTitleItemsToShow?[selectedRow]
            item.text = sender.stringValue
            self.tableView.reloadData()
        }
    }
    
    @IBAction func saveDocument(sender: AnyObject) {
        guard let subTitleItems = subTitleItemsToShow where subTitleItems.count != 0 else {
            return
        }
        
        let filePathWithoutExt = self.subTitleDoc!.filePathWithoutExt
        var filePath = filePathWithoutExt + ".srt"
        
        //get default file manager
        let fileManager = NSFileManager.defaultManager()
        
        //check file exist
        while fileManager.fileExistsAtPath(filePath) {
            filePath = filePathWithoutExt + "_\(fileNameIncrement++).srt"
        }
        
        self.outputLabel.stringValue = "Saved : \(filePath)\n"
        
        //create empty file
        let _ = fileManager.createFileAtPath(filePath, contents: nil, attributes: nil)
        
        //wirte data to file with utf-8
        if let fileHandle = NSFileHandle(forWritingAtPath: filePath) {
            defer {
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
        let rows = self.tableView.selectedRowIndexes
        self.removeItems(rows)
    }
    
    func changeIntervalInRange(items: [SubTitleData], type: ChangeType) -> Bool {
        self.outputLabel.stringValue = "Encoding : \(subTitleDoc!.encoding)"
        self.intervalTimeAmount = SubTitleTime(timeInStr: self.timePicker.intervalTimeString).milliseconds
        
        // check time integrity
        if type == .Pull {
            for item in items {
                let sTime = SubTitleTime(timeInStr: item.start)
                let eTime = SubTitleTime(timeInStr: item.end)
                
                if sTime.milliseconds - self.intervalTimeAmount < 0 || eTime.milliseconds - self.intervalTimeAmount < 0 {
                    self.outputLabel.stringValue = "Error : The reduced time will be less then 0"
                    return false
                }
            }
        }
        
        for item in items {
            let sTime = SubTitleTime(timeInStr: item.start)
            let eTime = SubTitleTime(timeInStr: item.end)
            
            let timeChange: (start: SubTitleTime, end: SubTitleTime) = (type == .Pull) ? (sTime - self.intervalTimeAmount, eTime - self.intervalTimeAmount) : (sTime + self.intervalTimeAmount, eTime + self.intervalTimeAmount)
            
            item.start = timeChange.start.getReadableTime()
            item.end = timeChange.end.getReadableTime()
        }
        
        return true
    }
    
    @IBAction func pullTiming(sender: AnyObject) {
        guard let subTitleItems = self.subTitleItemsToShow else {
            return
        }
        
        if self.changeRange == .All {
            if(changeIntervalInRange(subTitleItems, type: .Pull)) {
                self.tableView.reloadData()
            }
        } else if self.changeRange == .FromSelectedToEnd {
            let selectedRow = self.tableView.selectedRow
            if selectedRow != -1 {
                let lastRow = self.subTitleItemsToShow!.count - 1
                let items = Array(subTitleItems[selectedRow...lastRow])
                if(changeIntervalInRange(items, type: .Pull)) {
                    self.tableView.reloadData()
                    self.tableView.selectRowIndexes(NSIndexSet(index: selectedRow), byExtendingSelection: false)
                }
            }
        } else if self.changeRange == .OnlySelected {
            let selectedRow = self.tableView.selectedRow
            if selectedRow != -1 {
                let items = Array(arrayLiteral: subTitleItems[selectedRow])
                if(changeIntervalInRange(items, type: .Pull)) {
                    self.tableView.reloadData()
                    self.tableView.selectRowIndexes(NSIndexSet(index: selectedRow), byExtendingSelection: false)
                }
            }
        }
    }
    
    @IBAction func pushTiming(sender: AnyObject) {
        guard let subTitleItems = self.subTitleItemsToShow else {
            return
        }
        
        if self.changeRange == .All {
            if(changeIntervalInRange(subTitleItems, type: .Push)) {
                self.tableView.reloadData()
            }
        } else if self.changeRange == .FromSelectedToEnd {
            let selectedRow = self.tableView.selectedRow
            if selectedRow != -1 {
                let lastRow = self.subTitleItemsToShow!.count - 1
                let items = Array(subTitleItems[selectedRow...lastRow])
                if(changeIntervalInRange(items, type: .Push)) {
                    self.tableView.reloadData()
                    self.tableView.selectRowIndexes(NSIndexSet(index: selectedRow), byExtendingSelection: false)
                }
            }
        } else if self.changeRange == .OnlySelected {
            let selectedRow = self.tableView.selectedRow
            if selectedRow != -1 {
                let items = Array(arrayLiteral: subTitleItems[selectedRow])
                if(changeIntervalInRange(items, type: .Push)) {
                    self.tableView.reloadData()
                    self.tableView.selectRowIndexes(NSIndexSet(index: selectedRow), byExtendingSelection: false)
                }
            }
        }
    }
    
    @IBAction func checkApplyRange(sender: NSButton) {
        if sender.identifier == "fromFirstRow" {
            self.changeRange = .All
        } else if sender.identifier == "fromSelectedRow" {
            self.changeRange = .FromSelectedToEnd
        } else if sender.identifier == "onlySelectedRow" {
            self.changeRange = .OnlySelected
        } else {
            self.changeRange = .None
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
