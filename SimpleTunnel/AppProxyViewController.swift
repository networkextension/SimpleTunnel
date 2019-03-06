//
//  AppProxyViewController.swift
//  SimpleTunnel
//
//  Created by yarshure on 2017/12/17.
//  Copyright © 2017年 Apple Inc. All rights reserved.
//

import UIKit
import NetworkExtension
import WebKit
extension NEVPNStatus{
    func descript() ->String{
        switch self{
        case .disconnected:
            
            return  "Disconnect"
            
            
        case .invalid:
            
           return "Please Try Again"
           
        case .connected:
            
            return "Connected"
            
           
        case .connecting:
            
            return "Connecting"
            
        case .disconnecting:
            
            return "Disconnecting"
            
        case .reasserting:
            return   "Reasserting"
            
            
            
        @unknown default:
            fatalError()
        }
    }
}
class AppProxyViewController: UIViewController {
    var proxyManager:NEAppProxyProviderManager?// = NEAppProxyProviderManager()
    @IBOutlet weak var lable:UILabel!
    @IBOutlet weak var wk:WKWebView!
    override func viewDidLoad() {
        super.viewDidLoad()
        startLoading()
        let req = URLRequest.init(url: URL.init(string: "https://www.apple.com")!)
        self.wk.load(req)
         //initProviderManager()
        // Do any additional setup after loading the view.
    }
    @IBAction func start(_ sender: Any) {
        guard let manager = self.proxyManager else {
            return
        }
        let session = manager.connection as! NETunnelProviderSession
        if session.status != .connected{
            initProviderManager()
        }
        xpc()
        
    }
    private func initProviderManager() {
        guard let manager = self.proxyManager else {
            return
        }
        let session = manager.connection as! NETunnelProviderSession
        do {
            try session.startTunnel(options: nil)
        }
        catch {
            print(error)
        }
    }
    private func startLoading() {
       // guard case .loading = self.state else { fatalError() }
        NEAppProxyProviderManager.loadAllFromPreferences { (managers, error) in
            assert(Thread.isMainThread)
            if let error = error {
                //self.state = .failed(error: error)
                print(error.localizedDescription)
            } else {
                let manager = managers?.first ?? NEAppProxyProviderManager()
                //self.state = .loaded(snapshot: Snapshot(from: manager), manager: manager)
                self.proxyManager = manager
                self.ob(manager.connection)
                self.xpc()
                
            }
        }
    }
    
    func xpc(){
        guard let targetManager = self.proxyManager else {
            return
        }
        if let session = targetManager.connection as? NETunnelProviderSession,
            let message = "Hello Provider".data(using: String.Encoding.utf8)
            , targetManager.connection.status != .invalid{
            do {
                try session.sendProviderMessage(message, responseHandler: { (t) in
                    if let t = t ,let s = String.init(data: t, encoding: .utf8){
                       
                        print(s)
                    }
                })
            }catch let e {
                print("\(e.localizedDescription)")
            }
        }
    }
    func ob(_ connection:NEVPNConnection){
        self.lable.text =  connection.status.descript()
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NEVPNStatusDidChange, object:connection , queue: OperationQueue.main, using: { (t) in
            self.lable.text =  connection.status.descript()
            
        })
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

}
