//
//  ViewController.swift
//  SubTitleEditor
//
//  Created by 장기현 on 2015. 12. 15..
//  Copyright © 2015년 JKH. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet var output: NSTextView!
    @IBOutlet weak var tableView: NSTableView!
    
    var subTitleItmes: [SubTitleData]?
    var subTitleDoc: SubTitleDoc?
    
    let subTitle: String = "subTitle"
    
    var undoData: Array<[SubTitleData]> = Array<[SubTitleData]>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //tableView.setDelegate(self)
        //tableView.setDataSource(self)
        
        // Do any additional setup after loading the view.
        tableView.registerForDraggedTypes([subTitle, NSURLPboardType])
    }

    override var representedObject: AnyObject? {
        didSet {
            if let url = representedObject as? NSURL {
                print("opening file : \(url.path!)")
                
                output.logging(url.path!)
                
                subTitleDoc = SubTitleDocFactory.Create(url)
                reloadSubTitleData()
            }
        }
    }
    
    func reloadSubTitleData() {
        do {
            subTitleItmes = try subTitleDoc?.getSubTitleData()
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
    
    func addItems(items: AnyObject) {
        //undoManager?.prepareWithInvocationTarget(self).remove(rows)
        //undoManager?.setActionName("actions.add")
        print("addItems")
        
        for item: SubTitleData in items as! [SubTitleData] {
            print(item.text)
        }
        
    }
    
    func removeItems(rows: NSIndexSet) {
        var items: [SubTitleData] = [SubTitleData]()
        
        self.tableView.removeRowsAtIndexes(rows, withAnimation: .SlideUp)
        
        rows.enumerateIndexesWithOptions(.Reverse) {
            (index: Int, _) -> Void in
            
            let datum = self.subTitleItmes?.removeAtIndex(index)
            print(datum!.text)
            items.append(datum!)
        }
        
        //undoManager?.registerUndoWithTarget(self, selector: Selector("addItems:"), object: rows)
        //undoManager?.setActionName(NSLocalizedString("actions.remove", comment: "Remove Items"))
        
        undoManager?.prepareWithInvocationTarget(self).addItems(items)
        undoManager?.setActionName(NSLocalizedString("actions.remove", comment: "Remove Items"))
    }
}

extension ViewController: NSTableViewDataSource {
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return self.subTitleItmes?.count ?? 0
    }
    
    func tableView(tableView: NSTableView, writeRowsWithIndexes: NSIndexSet, toPasteboard: NSPasteboard) -> Bool {
        print("writeRowsWithIndexes")
        
        let data = NSKeyedArchiver.archivedDataWithRootObject([writeRowsWithIndexes])
        toPasteboard.declareTypes([subTitle], owner:self)
        toPasteboard.setData(data, forType:subTitle)
        
        return true
    }
    
    func tableView(tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableViewDropOperation) -> NSDragOperation
    {
        print("validateDrop")
        
        //get the file URLs from the pasteboard
        let pb: NSPasteboard = info.draggingPasteboard()
        
        if let _ = pb.dataForType(subTitle) {
            tableView.setDropRow(row, dropOperation: NSTableViewDropOperation.Above)
            return .Move
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
        print("acceptDrop")
        
        let pb = info.draggingPasteboard()
        
        if let data = pb.dataForType(subTitle) {
            let dataArray: [NSIndexSet]  = NSKeyedUnarchiver.unarchiveObjectWithData(data) as! [NSIndexSet]
            let indexSet = dataArray[0]
            let currentRow  = indexSet.firstIndex
            print("move \(currentRow) --> \(row)")
            
            let item = self.subTitleItmes![currentRow]
            print(item.text)
            
            if currentRow < row {
                //move down
                print("move down")
                
                /* in case of moving down
                 * 1. insert first
                 * 2. then remove
                */
                
                //insert moving item
                subTitleItmes!.insert(item, atIndex: row)
                tableView.insertRowsAtIndexes(NSIndexSet(index: row), withAnimation: .SlideLeft)
                
                //remove previous item
                subTitleItmes!.removeAtIndex(currentRow)
                tableView.removeRowsAtIndexes(NSIndexSet(index: currentRow), withAnimation: .EffectFade)
                
                return true
                
            } else if currentRow > row {
                //move up
                print("move up")
                
                /* in case of moving up
                 * 1. remove first
                 * 2. then insert
                */
                
                //remove item
                subTitleItmes!.removeAtIndex(currentRow)
                tableView.removeRowsAtIndexes(NSIndexSet(index: currentRow), withAnimation: .EffectFade)
                
                //insert moving item
                subTitleItmes!.insert(item, atIndex: row)
                tableView.insertRowsAtIndexes(NSIndexSet(index: row), withAnimation: .SlideRight)
                
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
        
        guard let item = self.subTitleItmes?[row] else {
            return nil
        }
        
        if tableColumn == tableView.tableColumns[0] {
            //text = item.num
            text = String(row+1)
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
        self.subTitleItmes?.removeAll()
        self.tableView.reloadData()
    }
    
    @IBAction func saveDocument(sender: AnyObject) {
        guard let subTitleItems = subTitleItmes where subTitleItems.count != 0 else {
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
        print("removeLine")
        let rows = self.tableView.selectedRowIndexes
        self.removeItems(rows)
    }
}

extension NSTextView {
    func logging(line: String, color: NSColor = NSColor.whiteColor()) {
        //set font and color
        let attriDict = [NSFontAttributeName: NSFont.boldSystemFontOfSize(12.0),
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