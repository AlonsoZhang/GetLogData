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
    
    var ConfigPlist = [String: Any]()
    var linenameDic = [String: Any]()
    var stationDic = [String: Any]()
    var file = ""
    var resultarray = [String]()
    var resultDic = [String: Any]()
    var tempDic = [String:Any]()
    
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
        LineName.title = "Temp"
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
    
    @IBAction func ExtractZip(_ sender: NSButton) {
    }
    
    func clickStation() {
        stationDic = ConfigPlist["Stations"] as! [String : Any]
        let clickstationDic: [String: Any] = stationDic[StationName.title] as? [String : Any] ?? [:]
        include.stringValue = (clickstationDic["IncludeString"] as? String ?? "TestResult : PASS||Uppdca: YES")!
        exclude.stringValue = (clickstationDic["ExcludeString"] as? String ?? "TestResult : FAIL||Uppdca: NO")!
        start.stringValue = (clickstationDic["StartString"] as? String ?? "")!
        end.stringValue = (clickstationDic["EndString"] as? String ?? "")!
        logformat.stringValue = (clickstationDic["LogFormat"] as? String ?? "")!
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
        resultarray.removeAll()
        resultDic.removeAll()
        tempDic.removeAll()
        showInfo.string = ""
        let url = URL(fileURLWithPath: folderPath.stringValue)
        let manager = FileManager.default
        let enumeratorAtPath = manager.enumerator(atPath: url.path)
        if checkformat() {
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
            if writelog() {
                showmessage(inputString: "\n\nFinish search and write log pass!")
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
        }
        print("tempDic:\(tempDic)")
        return result
    }
    
    func dealwithlog(log: String, path: String){
        let patharr: Array = path.components(separatedBy: "/")
        let logname = patharr[patharr.count - 1]
        let includearr = include.stringValue.components(separatedBy: "||")
        for containstr in includearr {
            if log.contains(containstr)||include.stringValue == "" {
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
                    if startarr.count == 1 {
                        resultarray.append(keystring)
                    }else{
                        middleDic["\(starteach.0)"] = keystring
                        //print(middleDic)
                    }
                }else{
                    showmessage(inputString: "No End string (\(endeacharr[0])):\(logname)")
                    return
                }
            }else{
                showmessage(inputString: "No Start string (\(starteacharr[0])):\(logname)")
                return
            }
            resultDic[logname] = middleDic
        }
    }
    
    func writelog() -> Bool {
        var result = true
        print(resultDic)
        let paths = NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true) as NSArray
        let creatfile = "\(paths[0])/\(StationName.title).csv"
        let formatstring = tempDic["FormatString"] as? String ?? ""
        var csvstring = "SN"
        for title in tempDic["TitleArray"] as? [String] ?? [String]() {
            csvstring.append(",\(title)")
        }
        csvstring.append("\n")
        let formatarr = formatstring.components(separatedBy: "$")
        
        for eachcsv in resultDic.keys {
            csvstring.append(eachcsv)
            for eachformat in formatarr {
                let each = regexdealwith(string: eachformat, pattern: "\\[.*?\\]", dict: resultDic[eachcsv] as! [String:Any])
                let finaleach = calc(string: each)
                csvstring.append(",\(finaleach)")
            }
            csvstring.append("\n")
        }
        
        
        //        for eachcsv in resultDic.keys {
        //
        //            //print(resultDic[eachcsv])
        //            var dic = [String: String]();
        //            dic = resultDic[eachcsv]! as! [String : String]
        //
        //            let aaa = Float(dic["1"]!)
        //            let bbb = Float(dic["0"]!)
        //            let eee = Float(dic["3"]!)
        //            let fff = Float(dic["2"]!)
        //            let num4 = Float(dic["4"] ?? "0")
        //            let num5 = Float(dic["5"] ?? "0")
        //            let num6 = Float(dic["6"] ?? "0")
        //            let num7 = Float(dic["7"] ?? "0")
        //
        //            var ccc = aaa! - bbb!
        //            if ccc<0{
        //                ccc = ccc+60
        //            }
        //            var ggg = eee! - fff!
        //            if ggg<0 {
        //                ggg = ggg+60
        //            }
        //
        //            var min = num5! - num4!
        //            if min < 0 {
        //                min = min+60
        //            }
        //
        //            var min2 = num7! - num6!
        //            if min2 < 0 {
        //                min2 = min2+60
        //            }
        //
        //            let ddd = String(format: "%.3f", ccc)
        //            let hhh = String(format: "%.3f", ggg)
        //            let kkk = String(format: "%.3f", min)
        //            let lll = String(format: "%.3f", min2)
        //
        //            //            let iii = ggg+ccc
        //            //            let jjj = String(format: "%.3f", iii)
        //
        //            csvstring.append("\(eachcsv),\(ddd),\(hhh),\(kkk),\(lll)\n")
        //        }
        do {
            try csvstring.write(toFile: creatfile, atomically: true, encoding: String.Encoding.utf8)
        } catch  {
            showmessage(inputString: "Error to write csv")
            result = false
        }
        
        if resultarray.count > 0 {
            let paths = NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true) as NSArray
            let finalDic = ["Source":resultarray]
            if plist.state == 1 {
                let creatfile = "\(paths[0])/\(StationName.title).plist"
                NSDictionary(dictionary: finalDic).write(toFile: creatfile, atomically: true)
            }else{
                var csvstring = "Source\n"
                for eachcsv in resultarray {
                    csvstring.append("\(eachcsv)\n")
                }
                let creatfile = "\(paths[0])/\(StationName.title).csv"
                do {
                    try csvstring.write(toFile: creatfile, atomically: true, encoding: String.Encoding.utf8)
                } catch  {
                    showmessage(inputString: "Error to write csv")
                    result = false
                }
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
//            if stringarr[0] =~  {
//                <#code#>
//            }
            let timeNumber = dateFormatter.date(from: "\(stringarr[1])" )!.timeIntervalSince1970-dateFormatter.date(from: "\(stringarr[0])" )!.timeIntervalSince1970
            print(timeNumber)
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
        if showInfo.string == "" {
            showInfo.string = inputString
        }else{
            showInfo.string = showInfo.string! + "\n\(inputString)"
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
    return MyRegex(rhs).match(input: lhs) //需要前面定义的MyRegex配合
}

