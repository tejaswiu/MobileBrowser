//
//  WKModelViewController.swift
//  ThemeChanger
//
//  Created by Tejaswi on 15/05/18.
//  Copyright © 2018 TEKsystems. All rights reserved.
//

import UIKit
import WebKit

class WKModelViewController: UIViewController, WKUIDelegate, WKNavigationDelegate {
    
    var username: String? = nil
    var password: String? = nil
    var request: URLRequest?
    
    var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Theme"
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        let searchButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonClicked))
        navigationItem.leftBarButtonItem = searchButton
        
        
    }
    
    @objc func cancelButtonClicked(sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
        
    }
    
    func createWebView(config: WKWebViewConfiguration, request: URLRequest) -> WKWebView {
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        preferences.javaScriptCanOpenWindowsAutomatically = true
        
        config.preferences = preferences
        
        webView = WKWebView(frame: view.bounds, configuration: config)
        
        if let theWebView = webView {
            let urlRequest = request
            theWebView.load(urlRequest)
            theWebView.navigationDelegate = self
            theWebView.uiDelegate = self
            return theWebView
            
        }
        return webView
    }
    
    func doesHaveCredentials() -> Bool {
        guard let _ = self.username else { return false }
        guard let _ = self.password else { return false }
        
        return true
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        //        if let host = navigationAction.request.url?.host {
        //            if host.contains("hackingwithswift.com") {
        //                decisionHandler(.allow)
        //                return
        //            }
        //        }
        
        //        if ( navigationAction.targetFrame == nil) {
        //            // WKWebView ignores links that open in new window
        //            //            [webView loadRequest:navigationAction.request];
        //            webView.load(navigationAction.request)
        //        }
        
        // always pass a policy to the decisionHandler
        decisionHandler(.allow)
        
    }
    
    func webView(_ webView: WKWebView,
                 didReceive challenge: URLAuthenticationChallenge,
                 completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
    {
        print("woe")
        
        print("got challenge")
        
        print(challenge.protectionSpace.authenticationMethod)
        
        guard challenge.previousFailureCount == 0 else {
            print("too many failures")
            self.username = nil
            self.password = nil
            challenge.sender?.cancel(challenge)
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodNTLM else {
            print("unknown authentication method \(challenge.protectionSpace.authenticationMethod)")
            completionHandler(Foundation.URLSession.AuthChallengeDisposition.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
            return
        }
        
        if self.doesHaveCredentials()
        {
            let credentials = URLCredential(user: self.username!, password: self.password!, persistence: .forSession)
            challenge.sender?.use(credentials, for: challenge)
            completionHandler(.useCredential, credentials)
        }
        else {
            //            challenge.sender?.cancel(challenge)
            //            completionHandler(.cancelAuthenticationChallenge, nil)
            DispatchQueue.main.async {
                self.presentLogin(challenge: challenge, completionHandler: completionHandler)
            }
        }
        
        
    }
    
    
    func presentLogin(challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void ) {
        let alertView = UIAlertController(title: "Please login", message: "You need to provide credentials to make this call.", preferredStyle: .alert)
        
        let loginAction = UIAlertAction(title: "Login", style: .default) { action in
            let username = alertView.textFields![0] as UITextField
            let password = alertView.textFields![1] as UITextField
            
            self.login(username: username.text, password: password.text)
            
            let credentials = URLCredential(user: self.username!, password: self.password!, persistence: .forSession)
            challenge.sender?.use(credentials, for:challenge)
            completionHandler(.useCredential, credentials)
            
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            challenge.sender?.cancel(challenge)
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
        
        alertView.addTextField { textField in
            textField.placeholder = "Username"
        }
        
        alertView.addTextField { textField in
            textField.placeholder = "Password"
            textField.isSecureTextEntry = true
        }
        
        alertView.addAction(cancelAction)
        alertView.addAction(loginAction)
        
        self.present(alertView, animated: true, completion: {})
    }
    
    func login(username: String?, password: String?) {
        self.username = username
        self.password = password
        self.webView.reload()
        
    }
    
}
