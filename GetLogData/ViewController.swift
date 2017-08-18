//
//  ViewController.swift
//  GetLogData
//
//  Created by Alonso on 2017/8/18.
//  Copyright © 2017年 Alonso. All rights reserved.
//

import Cocoa

class ViewController: NSViewController,DragLogDelegate {
    
    @IBOutlet weak var LineName: NSPopUpButton!
    @IBOutlet weak var StationName: NSPopUpButton!
    @IBOutlet var viewDropper: ViewDropper!
    @IBOutlet weak var folderPath: NSTextField!
    
    var ConfigPlist:NSDictionary = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        viewDropper.delegate = self
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
        print( (paths[0]))
        let file = Bundle.main.path(forResource:"Config", ofType: "plist")
        ConfigPlist = NSDictionary(contentsOfFile: file!)!
        let linenameDic: [String: Any] = ConfigPlist["AllSations"] as! [String : Any]
        for linename in linenameDic.keys {
            LineName.addItem(withTitle: linename)
        }
        let stationnameDic: [String: Any] = linenameDic[LineName.title] as! [String : Any]
        for stationname in stationnameDic.keys {
            StationName.addItem(withTitle: stationname)
        }
        
        
    }
    
    public func dragLog(_ files: [Any]!){
        if files.count > 1 {
            folderPath.textColor = NSColor.red
            folderPath.stringValue = "Please drag one folder once !!!"
        }else{
            folderPath.textColor = NSColor.blue
            let path = files[0]
            folderPath.stringValue = "\(path)"
        }
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func ChooseLine(_ sender: NSPopUpButton) {
        StationName.removeAllItems()
        let linenameDic: [String: Any] = ConfigPlist["AllSations"] as! [String : Any]
        let stationnameDic: [String: Any] = linenameDic[sender.title] as! [String : Any]
        for stationname in stationnameDic.keys {
            StationName.addItem(withTitle: stationname)
        }
    }
    
    @IBAction func ChooseStation(_ sender: NSPopUpButton) {
        print("select title \(sender.itemTitles[sender.indexOfSelectedItem]) \(sender.title)")
    }
    

}

