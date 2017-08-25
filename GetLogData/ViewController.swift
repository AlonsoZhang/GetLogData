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
    @IBOutlet weak var logformat: NSTextField!
    @IBOutlet var showInfo: NSTextView!
    @IBOutlet weak var saveBtn: NSButton!
    @IBOutlet weak var nouseTF: NSTextField!
    @IBOutlet weak var processbar: NSProgressIndicator!
    @IBOutlet weak var processLabel: NSTextField!
    @IBOutlet weak var scrollview: NSScrollView!
    
    var ConfigPlist = [String: Any]()
    var linenameDic = [String: Any]()
    var stationDic = [String: Any]()
    var file = ""
    var resultDic = [String: Any]()
    var tempDic = [String:Any]()
    var outputlogstr = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dragView.delegate = self
        self.plist.state = 0
        self.csv.state = 1
        file = Bundle.main.path(forResource:"Config", ofType: "plist")!
        ConfigPlist = NSDictionary(contentsOfFile: file)! as! [String : Any]
        linenameDic = ConfigPlist["AllSations"] as! [String : Any]
        for linename in linenameDic.keys {
            LineName.addItem(withTitle: linename)
        }
        LineName.title = "Temp"
        let stationnameDic: [String: Any] = linenameDic[LineName.title] as! [String : Any]
        for stationname in stationnameDic.keys {
            StationName.addItem(withTitle: stationname)
        }
        StationName.title = "Temp1"
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
        //print("select title \(sender.itemTitles[sender.indexOfSelectedItem]) \(sender.title)")
    }
    
    @IBAction func ExtractZip(_ sender: NSButton) {
        showInfo.string = ""
        if self.folderPath.stringValue == "" {
            showmessage(inputString: "Please drug log folder to here")
            return
        }
        nouseTF.isHidden = false
        processbar.isHidden = false
        processLabel.isHidden = false
        processbar.doubleValue = 0
        self.processLabel.stringValue = "Start Unzip log"
        let url = URL(fileURLWithPath: self.folderPath.stringValue)
        let manager = FileManager.default
        var enumeratorAtPath = manager.enumerator(atPath: url.path)
        var num = 0
        var process = 0
        for logpath in enumeratorAtPath! {
            if (logpath as AnyObject).hasSuffix(".zip") {
                num = num + 1
            }
        }
        DispatchQueue.global().async {
            let incrementnum = 100.0/Double(num)
            enumeratorAtPath = manager.enumerator(atPath: url.path)
            for logpath in enumeratorAtPath! {
                let truepath = "\(self.folderPath.stringValue)/\(logpath)"
                if truepath.hasSuffix(".zip"){
                    process = process + 1
                    DispatchQueue.main.async {
                        self.processLabel.stringValue = "\(process)/\(num)"
                        self.processbar.increment(by: Double(incrementnum))
                    }
                    let endRange = truepath.range(of: ".zip", options: .backwards, range: nil, locale: nil)
                    let folderpath = truepath.substring(to: (endRange?.lowerBound)!)
                    self.run(cmd: "unzip \(truepath) -d \(folderpath)")
                    self.run(cmd: "rm -rf \(truepath)")
                }
            }
            self.showmessage(inputString: "Unzip \(process) files")
            DispatchQueue.main.async {
                self.nouseTF.isHidden = true
                self.processbar.isHidden = true
                self.processLabel.isHidden = true
            }
        }
    }
    
    func clickStation() {
        stationDic = ConfigPlist["Stations"] as! [String : Any]
        let clickstationDic: [String: Any] = stationDic[StationName.title] as? [String : Any] ?? [:]
        include.stringValue = (clickstationDic["IncludeString"] as? String ?? "TestResult : PASS$Uppdca: YES")!
        exclude.stringValue = (clickstationDic["ExcludeString"] as? String ?? "TestResult : FAIL$Uppdca: NO")!
        start.stringValue = (clickstationDic["StartString"] as? String ?? "")!
        end.stringValue = (clickstationDic["EndString"] as? String ?? "")!
        logformat.stringValue = (clickstationDic["LogFormat"] as? String ?? "()")!
        saveSetting(saveBtn)
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
        stationDic["\(StationName.title)"] = ["IncludeString":"\(include.stringValue)", "ExcludeString":"\(exclude.stringValue)", "StartString":"\(start.stringValue)", "EndString":"\(end.stringValue)","LogFormat":"\(logformat.stringValue)"]
        ConfigPlist["Stations"] = stationDic
        NSDictionary(dictionary: ConfigPlist).write(toFile: file, atomically: true)
    }
    
    @IBAction func Outputlog(_ sender: NSButton) {
        showInfo.string = ""
        if self.folderPath.stringValue == "" {
            showmessage(inputString: "Please drug log folder to here")
            return
        }
        var process = 0
        nouseTF.isHidden = false
        processbar.isHidden = false
        processLabel.isHidden = false
        processbar.doubleValue = 0
        outputlogstr = String()
        let url = URL(fileURLWithPath: self.folderPath.stringValue)
        let manager = FileManager.default
        var enumeratorAtPath = manager.enumerator(atPath: url.path)
        var num = 0
        for _ in enumeratorAtPath! {
            num = num + 1
        }
        showmessage(inputString: "File count : \(num)\n")
        let timer =  DispatchSource.makeTimerSource(flags: [], queue:DispatchQueue.main)
        timer.scheduleRepeating(deadline: .now(), interval: .milliseconds(1000) ,leeway:.milliseconds(40))
        timer.setEventHandler {
            self.showInfo.string = self.outputlogstr
            if num > 10000{
                let percent = Double(process)/Double(num)*100
                self.processLabel.stringValue = String.init(format: "%.1f%%", percent)
                self.processbar.doubleValue = percent
            }
            if let height=self.scrollview.documentView?.bounds.size.height{
                var diff = height-self.scrollview.documentVisibleRect.height
                if diff < 0 {
                    diff = 0
                }
                self.scrollview.contentView.scroll(NSMakePoint(0, diff))
            }
        }
        if #available(OSX 10.12, *) {
            timer.activate()
        } else {
            // Fallback on earlier versions
        }
        DispatchQueue.global().async {
            self.resultDic.removeAll()
            self.tempDic.removeAll()
            let incrementnum = 100.0/Double(num)
            enumeratorAtPath = manager.enumerator(atPath: url.path)
            if self.checkformat() {
                for logpath in enumeratorAtPath! {
                    process = process + 1
                    if num < 10000{
                        DispatchQueue.main.async {
                            self.processLabel.stringValue = "\(process)/\(num)"
                            self.processbar.increment(by: Double(incrementnum))
                        }
                    }
                    let truepath = "\(self.folderPath.stringValue)/\(logpath)"
                    let tmpData = NSData.init(contentsOfFile: truepath)
                    if (tmpData != nil) {
                        let content = String.init(data: tmpData! as Data, encoding: String.Encoding.utf8)
                        if (content != nil) {
                            self.dealwithlog(log: content!, path: logpath as! String)
                        }else{
                            self.showmessage(inputString: "No string: \(logpath)")
                        }
                    }else{
                        self.showmessage(inputString: "\n========================================\nFolder: \(logpath)")
                    }
                }
                DispatchQueue.main.async {
                    timer.cancel()
                    self.processLabel.stringValue = "Writing Log..."
                }
                if self.writelog() {
                    self.showmessage(inputString: "\n\nFinish search and write log pass!")
                }
            }
            DispatchQueue.main.async {
                self.nouseTF.isHidden = true
                self.processbar.isHidden = true
                self.processLabel.isHidden = true
                self.showInfo.string = self.outputlogstr
                if let height=self.scrollview.documentView?.bounds.size.height{
                    var diff = height-self.scrollview.documentVisibleRect.height
                    if diff < 0 {
                        diff = 0
                    }
                    self.scrollview.contentView.scroll(NSMakePoint(0, diff))
                }
            }
        }
    }
    
    func checkformat() -> Bool {
        var result = true
        var startstring = start.stringValue
        var endstring = end.stringValue
        let startarr = startstring.components(separatedBy: "$")
        let endarr = endstring.components(separatedBy: "$")
        if startarr.count != endarr.count {
            showmessage(inputString: "Start string count (\(startarr.count)) ≠ End string count (\(endarr.count))")
            result = false
        }
        for starteach in startarr {
            let starteacharr = starteach.components(separatedBy: "++")
            if starteacharr.count != 2{
                if starteach == "CheckUOP"{
                    startstring = startstring.replacingOccurrences(of: starteach, with: "SET SN++-25$Func Call : Check_UOP++-25", options: NSString.CompareOptions.caseInsensitive, range:nil)
                }else if starteach.contains("Item["){
                    let itemstr = self.findStringInString(str: starteach, pattern: "(?<=\\[).*?(?=\\])")
                    let itemnum = Int(itemstr) ?? 0
                    if itemnum != 0 {
                        if starteach.contains("Query") {
                            startstring = startstring.replacingOccurrences(of: starteach, with: "========== Start Test Item [\(String(describing: itemnum))]++-25$Func Call: AEQuerySFC++-25", options: NSString.CompareOptions.caseInsensitive, range:nil)
                        }else{
                            startstring = startstring.replacingOccurrences(of: starteach, with: "========== Start Test Item [\(String(describing: itemnum))]++-25$========== Start Test Item [\(String(describing: itemnum+1))]++-25", options: NSString.CompareOptions.caseInsensitive, range:nil)
                        }
                    }else{
                        showmessage(inputString: "Format item[] is wrong")
                        result = false
                    }
                }else{
                    showmessage(inputString: "Start string ++ format is wrong")
                    result = false
                }
            }
        }
        for endeach in endarr {
            let endeacharr = endeach.components(separatedBy: "++")
            if endeacharr.count != 2{
                if endeach == "CheckUOP"{
                    endstring = endstring.replacingOccurrences(of: endeach, with: "SET SN++-2$Func Call : Check_UOP++-2", options: NSString.CompareOptions.caseInsensitive, range:nil)
                }else if endeach.contains("Item["){
                    let itemstr = self.findStringInString(str: endeach, pattern: "(?<=\\[).*?(?=\\])")
                    let itemnum = Int(itemstr) ?? 0
                    if itemnum != 0 {
                        if endeach.contains("Query") {
                            endstring = endstring.replacingOccurrences(of: endeach, with: "========== Start Test Item [\(String(describing: itemnum))]++-2$Func Call: AEQuerySFC++-2", options: NSString.CompareOptions.caseInsensitive, range:nil)
                        }else{
                            endstring = endstring.replacingOccurrences(of: endeach, with: "========== Start Test Item [\(String(describing: itemnum))]++-2$========== Start Test Item [\(String(describing: itemnum+1))]++-2", options: NSString.CompareOptions.caseInsensitive, range:nil)
                        }
                    }else{
                        showmessage(inputString: "Format item[] is wrong")
                        result = false
                    }
                }else{
                    showmessage(inputString: "End string ++ format is wrong")
                    result = false
                }
            }
        }
        let newstartarr = startstring.components(separatedBy: "$")
        let newendarr = endstring.components(separatedBy: "$")
        if newstartarr.count != newendarr.count {
            showmessage(inputString: "Final Start string count (\(startarr.count)) ≠ End string count (\(endarr.count))")
            result = false
        }
        
        var formatstring = logformat.stringValue
        let formatarr = formatstring.components(separatedBy: "$")
        let titlearray = self.findArrayInString(str: formatstring , pattern: "(?<=\\().*?(?=\\))")
        if formatarr.count != titlearray.count {
            showmessage(inputString: "Logformat count (\(formatarr.count)) ≠ Title count (\(titlearray.count))")
            result = false
        }
        formatstring = regexdealwith(string: formatstring, pattern: "\\(.*?\\)", dict: [:])
        if result {
            tempDic["FormatString"] = formatstring
            tempDic["StartString"] = startstring
            tempDic["EndString"] = endstring
            tempDic["TitleArray"] = titlearray
            showmessage(inputString:"Final data:\nStartString: \(String(describing: tempDic["StartString"]!))\nEndString: \(String(describing: tempDic["EndString"]!))\nFormatString: \(String(describing: tempDic["FormatString"]!))\nTitleArray: \(String(describing: tempDic["TitleArray"]!))")
        }
        return result
    }
    
    func dealwithlog(log: String, path: String){
        let patharr: Array = path.components(separatedBy: "/")
        let logname = patharr[patharr.count - 1]
        let includearr = include.stringValue.components(separatedBy: "$")
        for containstr in includearr {
            if log.contains(containstr)||include.stringValue == "" {
                //print(logname)
            }else{
                showmessage(inputString: "Include out(\(containstr)):\(logname)")
                return
            }
        }
        let excludearr = exclude.stringValue.components(separatedBy: "$")
        for notcontainstr in excludearr {
            if log.contains(notcontainstr) {
                showmessage(inputString: "Exclude out(\(notcontainstr)):\(logname)")
                return
            }else{
                //print(logname)
            }
        }
        let startarr = (tempDic["StartString"] as! String).components(separatedBy: "$")
        let endarr = (tempDic["EndString"] as! String).components(separatedBy: "$")
        var middleDic = [String: Any]()
        var logstring = log
        for starteach in startarr.enumerated() {
            let starteacharr = starteach.1.components(separatedBy: "++")
            if let startrange = logstring.range(of: starteacharr[0]) {
                let startoffsetnum = (Int(starteacharr[1]) ?? Int("0"))!
                let finalstartrange = logstring.index(startoffsetnum >= 0 ? startrange.upperBound : startrange.lowerBound, offsetBy: startoffsetnum)
                logstring = logstring.substring(from: finalstartrange)
                let endeacharr = endarr[starteach.0].components(separatedBy: "++")
                if let endrange = logstring.range(of: endeacharr[0]) {
                    let endoffsetnum = (Int(endeacharr[1]) ?? Int("0"))!
                    let finalendrange = logstring.index(endoffsetnum > 0 ? endrange.upperBound : endrange.lowerBound, offsetBy: endoffsetnum)
                    let keystring = logstring.substring(to: finalendrange)
                    middleDic["\(starteach.0)"] = keystring
                }else{
                    //showmessage(inputString: "No End string (\(endeacharr[0])):\(logname)")
                    if plist.state == 1{
                        return
                    }
                }
            }else{
                //showmessage(inputString: "No Start string (\(starteacharr[0])):\(logname)")
                if plist.state == 1{
                    return
                }
            }
            resultDic[logname] = middleDic
        }
    }
    
    func writelog() -> Bool {
        var result = true
        let paths = NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true) as NSArray
        let formatstring = tempDic["FormatString"] as? String ?? ""
        var csvstring = "SN"
        var resultarray = [String]()
        for title in tempDic["TitleArray"] as? [String] ?? [String]() {
            csvstring.append(",\(title)")
        }
        csvstring.append("\n")
        let formatarr = formatstring.components(separatedBy: "$")
        for eachcsv in resultDic.keys {
            csvstring.append(eachcsv)
            var midstr = String()
            for eachformat in formatarr {
                let each = regexdealwith(string: eachformat, pattern: "\\[.*?\\]", dict: resultDic[eachcsv] as! [String:Any])
                let finaleach = calc(string: each)
                csvstring.append(",\(finaleach)")
                midstr.append(" \(finaleach)")
            }
            midstr = midstr.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            resultarray.append(midstr)
            csvstring.append("\n")
        }
        if plist.state == 1 {
            let finalDic = ["Source":resultarray]
            let creatfile = "\(paths[0])/\(StationName.title).plist"
            NSDictionary(dictionary: finalDic).write(toFile: creatfile, atomically: true)
        }else{
            let creatfile = "\(paths[0])/\(StationName.title).csv"
            do {
                try csvstring.write(toFile: creatfile, atomically: true, encoding: String.Encoding.utf8)
            } catch  {
                showmessage(inputString: "Error to write csv")
                result = false
            }
        }
        return result
    }
    
    func calc(string:String) -> String {
        var finalstring = string
        if string.contains("to") {
            let stringarr = string.components(separatedBy: "to")
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
            var timeNumber = Double()
            if stringarr[0] =~ "^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}.[0-9]{3}$" && stringarr[1] =~ "^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}.[0-9]{3}$" {
                timeNumber = dateFormatter.date(from: "\(stringarr[1])" )!.timeIntervalSince1970-dateFormatter.date(from: "\(stringarr[0])" )!.timeIntervalSince1970
                finalstring = String(format: "%.3f",timeNumber)
            }else{
                finalstring = ""
                if stringarr[0] != "" && stringarr[1] != "" {
                    showmessage(inputString: "Date format is error.\(stringarr[0]) to \(stringarr[1])")
                }
            }
        }
        return finalstring
    }
    
    func regexdealwith(string:String, pattern:String, dict:[String:Any]) -> String
    {
        var result = ""
        let resultArray = self.findArrayInString(str: string , pattern: pattern)
        var tmpString = string
        for str in resultArray
        {
            var tmpStr = str
            tmpStr.remove(at: tmpStr.startIndex)
            tmpStr.remove(at: tmpStr.index(before: tmpStr.endIndex))
            if let value = dict[tmpStr]
            {
                tmpString = tmpString.replacingOccurrences(of: str, with: value as! String)
            }else
            {
                tmpString = tmpString.replacingOccurrences(of: str, with: "")
            }
        }
        result.append(tmpString)
        result = result.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        return result
    }
    
    func findArrayInString(str:String , pattern:String ) -> [String]
    {
        do {
            var stringArray = [String]();
            let regex = try NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.caseInsensitive)
            let res = regex.matches(in: str, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, str.characters.count))
            for checkingRes in res
            {
                let tmp = (str as NSString).substring(with: checkingRes.range)
                stringArray.append(tmp.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines))
            }
            return stringArray
        }
        catch
        {
            showmessage(inputString: "findArrayInString Regex error")
            return [String]()
        }
    }
    
    func findStringInString(str:String , pattern:String ) -> String
    {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.caseInsensitive)
            let res = regex.firstMatch(in: str, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, str.characters.count))
            if let checkingRes = res
            {
                return ((str as NSString).substring(with: checkingRes.range)).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            }
            return ""
        }
        catch
        {
            showmessage(inputString: "findStringInString Regex error")
            return ""
        }
    }
    
    func showmessage(inputString: String) {
        DispatchQueue.main.async {
            if self.showInfo.string == "" {
                self.outputlogstr = inputString
                self.showInfo.string = self.outputlogstr
            }else{
                self.outputlogstr = self.outputlogstr + "\n\(inputString)"
            }
        }
    }
    
    func run(cmd:String) {
        var error: NSDictionary?
        NSAppleScript(source: "do shell script \"\(cmd)\"")!.executeAndReturnError(&error)
        if error != nil {
            showmessage(inputString: "\(String(describing: error))")
        }
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

import Foundation
struct MyRegex {
    let regex: NSRegularExpression?
    init(_ pattern: String) {
        regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
    }
    
    func match(input: String) -> Bool {
        if let matches = regex?.matches(in: input,options: [],range: NSMakeRange(0, (input as NSString).length)) {
            return matches.count > 0
        }
        else {
            return false
        }
    }
}

precedencegroup ComparisonPrecedence{
    associativity: none
    higherThan: LogicalConjunctionPrecedence
}
infix operator =~ : ComparisonPrecedence

func =~ (lhs: String, rhs: String) -> Bool {
    return MyRegex(rhs).match(input: lhs)
}

