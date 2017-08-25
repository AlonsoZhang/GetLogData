//
//  WebViewController.swift
//  GetLogData
//
//  Created by Alonso on 2017/8/25.
//  Copyright © 2017年 Alonso. All rights reserved.
//

import Cocoa
import WebKit

class WebViewController: NSViewController,WKUIDelegate {

    @IBOutlet weak var helpWeb: WKWebView!
    
    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        let rect = CGRect(x: 0, y: 0, width: 600, height: 600)
        helpWeb = WKWebView(frame: rect, configuration: webConfiguration)
        helpWeb.uiDelegate = self
        view = helpWeb
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let htmlFile:String = Bundle.main.path(forResource: "SW", ofType: "html")!
        let htmlData = NSData.init(contentsOfFile: htmlFile)
        let baseURL = URL(fileURLWithPath: Bundle.main.bundlePath)
        self.helpWeb.load(htmlData! as Data, mimeType: "text/html", characterEncodingName: "UTF-8", baseURL: baseURL)
    }
    
}
