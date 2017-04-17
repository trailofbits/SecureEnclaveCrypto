//
//  ErrorViewController.swift
//  SecureEnclaveDemo
//
//  Created by Alexander Antipov on 3/27/17.
//  Copyright © 2017 Ages. All rights reserved.
//

import UIKit
import WebKit

class ErrorViewController: UIViewController, WKNavigationDelegate {

    var url: String!
    var webView: WKWebView!

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var loadingActivityIndicator: UIActivityIndicatorView!
    
    override func loadView() {
        
        super.loadView()
        
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: containerView.bounds, configuration: webConfiguration)
        webView.navigationDelegate = self
        containerView.addSubview(webView)
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let url = URL(string: self.url)
        let request = URLRequest(url: url!)
        webView.load(request)
        
        containerView.bringSubview(toFront: loadingActivityIndicator)
        loadingActivityIndicator.startAnimating()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        loadingActivityIndicator.stopAnimating()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        
        loadingActivityIndicator.stopAnimating()
    }
    
    @IBAction func close(_ sender: Any) {
        
        self.dismiss(animated: true);
    }
}
