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
    @IBOutlet weak var saveBtn: NSButton!
    
    var ConfigPlist = [String: Any]()
    var linenameDic = [String: Any]()
    var stationDic = [String: Any]()
    var file = ""
    var resultarray = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dragView.delegate = self
        self.plist.state = 1
        self.csv.state = 0
        file = Bundle.main.path(forResource:"Config", ofType: "plist")!
        ConfigPlist = NSDictionary(contentsOfFile: file)! as! [String : Any]
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
        resultarray.removeAll()
        let url = URL(fileURLWithPath: folderPath.stringValue)
        let manager = FileManager.default
        let enumeratorAtPath = manager.enumerator(atPath: url.path)
        for logpath in enumeratorAtPath! {
            let truepath = "\(folderPath.stringValue)/\(logpath)"
            let tmpData = NSData.init(contentsOfFile: truepath)
            if (tmpData != nil) {
                let content = String.init(data: tmpData! as Data, encoding: String.Encoding.utf8)
                if (content != nil) {
                    dealwithlog(log: content!, path: logpath as! String)
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
        let clickstationDic: [String: Any] = stationDic[StationName.title] as? [String : Any] ?? [:]
        include.stringValue = (clickstationDic["IncludeString"] as? String ?? "111")!
        exclude.stringValue = (clickstationDic["ExcludeString"] as? String ?? "222")!
        start.stringValue = (clickstationDic["StartString"] as? String ?? "333")!
        end.stringValue = (clickstationDic["EndString"] as? String ?? "444")!
        saveSetting(saveBtn)
    }
    
    func dealwithlog(log: String, path: String){
        let patharr: Array = path.components(separatedBy: "/")
        let logname = patharr[patharr.count - 1]
        let includearr = include.stringValue.components(separatedBy: "||")
        for containstr in includearr {
            if log.contains(containstr) {
                //print(logname)
            }else{
                showmessage(inputString: "Include out(\(containstr)):\(logname)")
                return
            }
        }
        let excludearr = exclude.stringValue.components(separatedBy: "||")
        for notcontainstr in excludearr {
            if log.contains(notcontainstr) {
                showmessage(inputString: "Exclude out(\(notcontainstr)):\(logname)")
                return
            }else{
                //print(logname)
            }
        }
        let startarr = start.stringValue.components(separatedBy: "$")
        let endarr = end.stringValue.components(separatedBy: "$")
        if startarr.count != endarr.count {
            showmessage(inputString: "Start string count (\(startarr.count)) ≠ End string count (\(endarr.count)):\(logname)")
            return
        }
        for endeach in endarr {
            let endeacharr = endeach.components(separatedBy: "++")
            if endeacharr.count != 2{
                showmessage(inputString: "End string ++ format is wrong:\(logname)")
                return
            }
        }
        for starteach in startarr.enumerated() {
            let starteacharr = starteach.1.components(separatedBy: "++")
            if starteacharr.count != 2{
                showmessage(inputString: "Start string ++ format is wrong:\(logname)")
                return
            }
            //            let startRange = log.range(of: starteacharr[0])
            //            let endeacharr = endarr[starteach.0].components(separatedBy: "++")
            //            let endRange = log.range(of: endeacharr[0], options: .backwards, range: nil, locale: nil)
            //            let searchRange = (startRange?.upperBound)! ..< (endRange?.lowerBound)!
            //            let result = log.substring(with: searchRange)
            //            print(result)
            if let startrange = log.range(of: starteacharr[0]) {
                var keystring = log.substring(from: startrange.upperBound)
                let endeacharr = endarr[starteach.0].components(separatedBy: "++")
                if let endrange = keystring.range(of: endeacharr[0]) {
                    keystring = keystring.substring(to: endrange.lowerBound)
                    if startarr.count == 1 {
                        resultarray.append(keystring)
                    }
                }else{
                    showmessage(inputString: "No End string (\(endeacharr[0])):\(logname)")
                    return
                }
            }else{
                showmessage(inputString: "No Start string (\(starteacharr[0])):\(logname)")
                return
            }
        }
        
        if resultarray.count > 0 {
            let paths = NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true) as NSArray
            let resultDic = ["Source":resultarray]
            if plist.state == 1 {
                let creatfile = "\(paths[0])/\(StationName.title).plist"
                NSDictionary(dictionary: resultDic).write(toFile: creatfile, atomically: true)
            }else{
                var csvstring = "Source\n"
                for eachcsv in resultarray {
                    csvstring.append("\(eachcsv)\n")
                }
                let creatfile = "\(paths[0])/\(StationName.title).csv"
                do {
                    try csvstring.write(toFile: creatfile, atomically: true, encoding: String.Encoding.utf8)
                } catch  {
                    showmessage(inputString: "Error:\(logname)")
                    return
                }
            }
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
        showInfo.string = ""
    }
    
    @IBAction func saveSetting(_ sender: NSButton) {
        stationDic["\(StationName.title)"] = ["IncludeString":"\(include.stringValue)", "ExcludeString":"\(exclude.stringValue)", "StartString":"\(start.stringValue)", "EndString":"\(end.stringValue)"]
        ConfigPlist["Stations"] = stationDic
        NSDictionary(dictionary: ConfigPlist).write(toFile: file, atomically: true)
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

