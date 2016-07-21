//
//  Console.swift
//  ConsoleApp
//
//  Created by wookyoung on 3/13/16.
//  Copyright © 2016 factorcat. All rights reserved.
//

import UIKit
import Swifter
import NetUtils

public class AppConsole {
    
    var initial: AnyObject
    let server = HttpServer()

    public init(initial: AnyObject) {
        self.initial = initial
    }
    
    // MARK: AppConsole - run
    public func run(port: Int = 8080, _ block: (ConsoleRouter->Void)? = nil) -> String {
        let router = ConsoleRouter()
        router.route(server, initial: initial)
        try! server.start(UInt16(port), forceIPv4: false)
        let url = "http://\(localip()):\(port)"
        Log.info("AppConsole Server has started on \(url)")
        block?(router)
        return url
    }
    
    func localip() -> String {
        var ipv6s = [String]()
        var ipv4s = [String]()
        for interface in Interface.allInterfaces() {
            if (interface.name == "en0") {
                if let addr = interface.address {
//                    Log.info("interface \(interface.debugDescription)")
                    if ["IPv6"].contains(interface.family.toString()) {
                        if "fe80::" != addr {
                            ipv6s.append(addr)
                        }
                    } else {
                        ipv4s.append(addr)
                    }
                }
            }
        }
        if ipv6s.count > 0 {
            if let ipv6 = ipv6s.first  {
                return ipv6
            }
        } else {
            if let ipv4 = ipv4s.first  {
                return ipv4
            }
        }
        return "localhost"
    }
}