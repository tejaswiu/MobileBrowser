//
//  MobileBrowserView.swift
//  TekBaseFramework
//
//  Created by Tejaswi on 24/05/18.
//  Copyright © 2018 Anil Manoharrao. All rights reserved.
//

import UIKit
import WebKit

enum toolBarPosition {
    case top
    case bottom
}


class MobileBrowserView: UIView, WKNavigationDelegate, WKUIDelegate {
    
    @IBOutlet var contentView: UIView!
    
    var webView: WKWebView!
    @IBOutlet var toolBar: UIToolbar!
    
    
    var urlString = "" {
        didSet {
            loadWebView()
        }
    }
    
    var baseViewController =  UIViewController()
    var leftBarButton = UIBarButtonItem()
    var rightBarButton = UIBarButtonItem()
    
    init(frame: CGRect, withURLString: String, onView: UIViewController){
        self.urlString = withURLString
        self.baseViewController = onView
        super.init(frame:frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder:coder)
        if self.subviews.count == 0 {
            commonInit()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func commonInit() {
        
        if let view = Bundle.main.loadNibNamed("MobileBrowserView", owner: self, options: nil)?.first as? MobileBrowserView {
            view.frame = self.bounds
            view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            addSubview(view)
            self.setNeedsLayout()
        }
        
    }
    
    func loadWebView() {
        if let url = URL(string: self.urlString) {
            let request = URLRequest(url: url)
            createWebView(config:WKWebViewConfiguration() , request: request)
            addToolBar()
        }
        else {
            let alert = UIAlertController(title: "Error!", message: "Invalid request.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
            self.baseViewController.present(alert, animated: true, completion: nil)
        }
    }
    private func createWebView(config: WKWebViewConfiguration, request: URLRequest)  {
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        preferences.javaScriptCanOpenWindowsAutomatically = true
        
        config.preferences = preferences
        
        if (webView != nil) {
            webView.removeFromSuperview()
        }
        webView = WKWebView(frame: CGRect.zero, configuration: config)
        webView.allowsBackForwardNavigationGestures = true
        webView.backgroundColor = .red
        let webViewKeyPathsToObserve = ["loading"]
        for keyPath in webViewKeyPathsToObserve {
            webView.addObserver(self, forKeyPath: keyPath, options: .new, context: nil)
        }
        let urlRequest = request
        webView.load(urlRequest)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        
        self.contentView.addSubview(webView)
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|-0-[webView]-0-|",
                                                           options: NSLayoutFormatOptions(rawValue: 0),
                                                           metrics: nil,
                                                           views: ["webView": webView]))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[webView]-0-|",
                                                           options: NSLayoutFormatOptions(rawValue: 0),
                                                           metrics: nil,
                                                           views: ["webView": webView]))
        
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let keyPath = keyPath else { return }
        
        switch keyPath {
            
        case "loading":
            // If you have back and forward buttons, then here is the best time to enable it
            leftBarButton.isEnabled = webView.canGoBack
            rightBarButton.isEnabled = webView.canGoForward
            
        case "estimatedProgress": break
            // If you are using a `UIProgressView`, this is how you update the progress
            //            progressView.hidden = webView.estimatedProgress == 1
            //            progressView.progress = Float(webView.estimatedProgress)
            
        default:
            break
        }
    }
    
    func addToolBar() {
        print(UIApplication.shared.statusBarFrame.height)//44 for iPhone x, 20 for other iPhones
        
        var items = [UIBarButtonItem]()
        leftBarButton = UIBarButtonItem(image: UIImage(named: "prev"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(prevButtonClicked(sender:)))
        rightBarButton = UIBarButtonItem(image: UIImage(named: "next"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(nextButtonClicked(sender:)))
        items.append(leftBarButton)
        items.append(rightBarButton)
        
        toolBar.setItems(items, animated: true)
    }
    
    func updateToolBars() {
        if self.webView.canGoBack {
            leftBarButton.isEnabled = true
        }
        else {
            leftBarButton.isEnabled = false
        }
        if self.webView.canGoForward {
            rightBarButton.isEnabled = true
        }
        else {
            rightBarButton.isEnabled = false
        }
        
    }
    
    @objc func customGoBack(_ sender: UIButton) {
        if self.webView.canGoBack {
            print("Can go back")
            self.webView.goBack()
        } else {
            print("Can't go back")
            let alert = UIAlertController(title: "Hello!", message: "You can't go back!", preferredStyle: UIAlertControllerStyle.alert)
            
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
            
            self.baseViewController.present(alert, animated: true, completion: nil)
        }
    }
    
    @objc func prevButtonClicked(sender: UIButton) {
        self.customGoBack(sender)
    }
    
    @objc func nextButtonClicked(sender: UIButton) {
        
        if self.webView.canGoForward {
            self.webView.goForward()
        }
        else {
            let alert = UIAlertController(title: "Hello!", message: "You can't go forward!", preferredStyle: UIAlertControllerStyle.alert)
            
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
            
            self.baseViewController.present(alert, animated: true, completion: nil)
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        //            progressView.setProgress(0.0, animated: false)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // always pass a policy to the decisionHandler
        updateToolBars()
        decisionHandler(.allow)
    }
    
    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        print(navigationAction.navigationType)
        
        let vc = WKModelViewController()
        
        let newWebView = vc.createWebView(config: configuration, request: navigationAction.request)
        vc.view.addSubview(newWebView)
        let navController = UINavigationController(rootViewController: vc)
        self.baseViewController.navigationController?.present(navController, animated: true, completion: nil)
        
        return nil;
    }
    
    
}
