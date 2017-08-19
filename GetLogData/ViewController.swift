//
//  ViewController.swift
//  GetLogData
//
//  Created by Alonso on 2017/8/18.
//  Copyright © 2017年 Alonso. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    @IBOutlet weak var LineName: NSPopUpButton!
    @IBOutlet weak var StationName: NSPopUpButton!
    @IBOutlet var dragView: FileDragView!
    @IBOutlet weak var folderPath: NSTextField!
    @IBOutlet weak var csv: NSButton!
    @IBOutlet weak var plist: NSButton!
    @IBOutlet weak var include: NSTextField!
    @IBOutlet weak var exclude: NSTextField!
    @IBOutlet weak var start: NSTextField!
    @IBOutlet weak var end: NSTextField!
    @IBOutlet var showInfo: NSTextView!
    
    var ConfigPlist:NSDictionary = [:]
    var linenameDic:[String: Any] = [:]
    var stationDic:[String: Any] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dragView.delegate = self
        self.plist.state = 1
        self.csv.state = 0
        let paths = NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true) as NSArray
        print(paths[0])
        let file = Bundle.main.path(forResource:"Config", ofType: "plist")
        ConfigPlist = NSDictionary(contentsOfFile: file!)!
        linenameDic = ConfigPlist["AllSations"] as! [String : Any]
        for linename in linenameDic.keys {
            LineName.addItem(withTitle: linename)
        }
        let stationnameDic: [String: Any] = linenameDic[LineName.title] as! [String : Any]
        for stationname in stationnameDic.keys {
            StationName.addItem(withTitle: stationname)
        }
        clickStation()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func ChooseLine(_ sender: NSPopUpButton) {
        StationName.removeAllItems()
        let stationnameDic: [String: Any] = linenameDic[sender.title] as! [String : Any]
        for stationname in stationnameDic.keys {
            StationName.addItem(withTitle: stationname)
        }
        clickStation()
    }
    
    @IBAction func ChooseStation(_ sender: NSPopUpButton) {
        clickStation()
        print("select title \(sender.itemTitles[sender.indexOfSelectedItem]) \(sender.title)")
    }
    
    @IBAction func Outputlog(_ sender: NSButton) {
        let url = URL(fileURLWithPath: folderPath.stringValue)
        let manager = FileManager.default
        let enumeratorAtPath = manager.enumerator(atPath: url.path)
        for logpath in enumeratorAtPath! {
            let truepath = "\(folderPath.stringValue)/\(logpath)"
            let tmpData = NSData.init(contentsOfFile: truepath)
            if (tmpData != nil) {
                let content = String.init(data: tmpData! as Data, encoding: String.Encoding.utf8)
                if (content != nil) {
                    if (content?.contains("TestResult : PASS ;"))! {
                        print(truepath)
                    }else{
                        print("fail")
                    }
                }else{
                    showmessage(inputString: "No string: \(logpath)")
                }
            }else{
                showmessage(inputString: "\n========================================\nFolder: \(logpath)")
            }
        }
    }
    
    func showmessage(inputString: String) {
        if showInfo.string == "" {
            showInfo.string = inputString
        }else{
            showInfo.string = showInfo.string! + "\n\(inputString)"
        }
    }
    
    func clickStation() {
        stationDic = ConfigPlist["Stations"] as! [String : Any]
        if stationDic[StationName.title] != nil{
            let clickstationDic: [String: Any] = stationDic[StationName.title] as! [String : Any]
            include.stringValue = (clickstationDic["IncludeString"] as? String ?? "")!
            exclude.stringValue = (clickstationDic["ExcludeString"] as? String ?? "")!
            start.stringValue = (clickstationDic["StartString"] as? String ?? "")!
            end.stringValue = (clickstationDic["EndString"] as? String ?? "")!
            print(clickstationDic)
        }else{
            print("empty")
        }
    }
    
    @IBAction func chooseCSV(_ sender: NSButton) {
        self.plist.state = 0
        self.csv.state = 1
    }
    
    @IBAction func choosePlist(_ sender: NSButton) {
        self.plist.state = 1
        self.csv.state = 0
    }
    
    @IBAction func cleanInfo(_ sender: NSButton) {
    }
    
    @IBAction func saveSetting(_ sender: NSButton) {
    }

}

extension ViewController: FileDragDelegate {
    func didFinishDrag(_ files:Array<Any>){
        if files.count > 1 {
            folderPath.textColor = NSColor.red
            folderPath.stringValue = "Please drag one folder once !!!"
        }else{
            folderPath.textColor = NSColor.blue
            let path = files[0]
            folderPath.stringValue = "\(path)"
        }
    }
}

