//
//  AppProxyViewController.swift
//  SimpleTunnel
//
//  Created by yarshure on 2017/12/17.
//  Copyright © 2017年 Apple Inc. All rights reserved.
//

import UIKit
import NetworkExtension
class AppProxyViewController: UIViewController {
    var proxyManager:NEAppProxyProviderManager?// = NEAppProxyProviderManager()
    override func viewDidLoad() {
        super.viewDidLoad()
        startLoading()
         //initProviderManager()
        // Do any additional setup after loading the view.
    }
    @IBAction func start(_ sender: Any) {
        initProviderManager()
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
            }
        }
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
