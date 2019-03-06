//
//  ViewController.swift
//  mac
//
//  Created by 孔祥波 on 05/01/2018.
//  Copyright © 2018 Apple Inc. All rights reserved.
//

import Cocoa
import NetworkExtension
class ViewController: NSViewController {

    var manager:NETunnelProviderManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        loadManager()
        // Do any additional setup after loading the view.
    }
    @IBAction func save(_ sender: Any) {
        guard self.manager != nil else {
            fatalError()
        }
        
    }
    
    func loadManager(){
        NETunnelProviderManager.loadAllFromPreferences { (ms, e) in
            print(ms as Any)
            if let ms = ms{
                if ms.count != 0 {
                    for m in ms {
                        self.manager = m
                    }
                }else {
                    self.create()
                }
            }
        }
    }
     @IBAction func dail(_ sender: Any) {
        _ = try! startStopToggled("")
    }
    func create(){
        let config = NETunnelProviderProtocol()
        //config.providerConfiguration = ["App": bId,"PluginType":"com.yarshure.Surf"]
        #if os(iOS)
            
            config.providerBundleIdentifier = "com.yarshure.Surf.PacketTunnel"
        #else
            config.providerBundleIdentifier = "com.yarshure.Surf.mac.extension"
        #endif
        config.serverAddress = "192.168.11.9:8890"
        
        let manager = NETunnelProviderManager()
        manager.protocolConfiguration = config
       manager.localizedDescription = "Surfing"
        
        
        
        manager.saveToPreferences(completionHandler: { (error) -> Void in
            if error != nil {
                print(error?.localizedDescription as Any)
            }else {
                self.manager = manager
            }
            
        })
    
    }
    func startStopToggled(_ config:String) throws ->Bool{
        if let m = manager {
           
            if m.connection.status == .disconnected || m.connection.status == .invalid {
                do {
                    
                    if  m.isEnabled {
                        
                        try m.connection.startVPNTunnel(options: [:])
                        
                        
                        
                        
                        
                    }else {
                        
                    }
                }
                catch let error  {
                    throw error
                    //mylog("Failed to start the VPN: \(error)")
                }
            }
            else {
                print("stoping!!!")
                m.connection.stopVPNTunnel()
            }
        }else {
            
            return false
        }
        return true
    }
    @IBAction func XPC(_ sender: Any) {
        // Send a simple IPC message to the provider, handle the response.
        //AxLogger.log("send Hello Provider")
        if let m = manager {
            let me = "|Hello Provider"
            if let session = m.connection as? NETunnelProviderSession,
                let message = me.data(using: .utf8), m.connection.status != .invalid
            {
                do {
                    try session.sendProviderMessage(message) { response in
                        if let response = response  {
                            if let responseString = String.init(data:response , encoding: .utf8){
                                _ = responseString.components(separatedBy: ":")
                                
                                print("Received response from the provider: \(responseString)")
                            }
                            
                            //self.registerStatus()
                        } else {
                            print("Got a nil response from the provider")
                        }
                    }
                } catch {
                    print("Failed to send a message to the provider")
                }
            }
        }else {
            print("message dont init")
        }
        
    }
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

