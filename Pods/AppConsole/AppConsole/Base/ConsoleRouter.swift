//
//  ConsoleRouter.swift
//  ConsoleApp
//
//  Created by wookyoung on 3/13/16.
//  Copyright © 2016 factorcat. All rights reserved.
//

import UIKit
import Swifter

enum ChainType {
    case Go
    case Stop
}

enum TypeMatchType {
    case Match
    case None
}

typealias ChainResult = (ChainType, AnyObject?)
typealias TypeMatchResult = (TypeMatchType, AnyObject?)

public class ConsoleRouter {
    
    let type_handler = TypeHandler()
    var env = [String: AnyObject]()

    // MARK: ConsoleRouter - route
    func route(server: HttpServer, initial: AnyObject) {

        server["/"] = { req in
            return .OK(.Html("<html><head><title>iOS REPL with Swifter.jl + AppConsole</title></head><body>iOS REPL with <a href=\"https://github.com/wookay/Swifter.jl\">Swifter.jl</a> +  <a href=\"https://github.com/wookay/AppConsole\">AppConsole</a></body></html>"))
        }

        server["/initial"] = { req in
            return self.result(initial)
        }
        
        server["/image"] = { req in
            for (name, value) in req.queryParams {
                if "path" == name {
                    var lhs = [TypePair]()
                    do {
                        if let data = value.dataUsingEncoding(NSUTF8StringEncoding),
                            let json = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) as? [AnyObject] {
                            lhs = self.typepairs(json)
                        }
                    } catch {
                    }
                    let (_,object) = self.chain(nil, lhs, full: true)
                    if let view = object as? UIView {
                        return self.result_image(view.to_data())
                    } else if let screen = object as? UIScreen {
                        return self.result_image(screen.to_data())
                    }
                } else if "address" == name {
                    if let view = self.from_address(value) as? UIView {
                        return self.result_image(view.to_data())
                    }
                }
            }
            return self.result_failed()
        }

        server["/query"] = { req in
            var query = [String: AnyObject]()
            do {
                let data = NSData(bytes: req.body, length: req.body.count)
                query = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) as! [String: AnyObject]
            } catch {
            }

            if let type = query["type"] as? String, lhs = query["lhs"] as? [AnyObject] {
                switch type {
                case "Getter":
                    let (success,object) = self.chain_getter(lhs)
                    if case .Go = success {
                        if let obj = object {
                            return self.result(obj)
                        } else {
                            return self.result_nil()
                        }
                    } else {
                        return self.result_failed(object)
                    }
                case "Setter":
                    if let rhs = query["rhs"] as? [AnyObject] {
                        let (success, left) = self.chain(nil, self.typepairs(lhs), full: false)
                        let (_, value) = self.chain_getter(rhs)
                        if case .Go = success {
                            if let obj = left {
                                dispatch_async(dispatch_get_main_queue(), {
                                    self.chain_setter(obj, lhs: lhs, value: value)
                                })
                                if let val = value {
                                    return self.result(val)
                                } else {
                                    return self.result_nil()
                                }
                            } else {
                                return self.result_nil()
                            }
                        } else {
                            return self.result_failed()
                        }
                    }
                default:
                    break
                }
            }
            return self.result_failed()
        }
    }
}



// MARK: ConsoleRouter - chains

extension ConsoleRouter {
    
    func chain_getter(lhs: [AnyObject]) -> ChainResult {
        let vec: [TypePair] = typepairs(lhs)
        return chain(nil, vec, full: true)
    }

    func chain_setter(obj: AnyObject, lhs: [AnyObject], value: AnyObject?) -> AnyObject? {
        let vec: [TypePair] = typepairs(lhs)
        if let pair = vec.last {
            var val = value
            let method = pair.second as! String
            if let str = value as? String {
                if "@" == ns_return_types(obj, method) {
                    if str.hasPrefix("<UICTFont: 0x") {
                        if let font = UIFontFromString(str) {
                            val = font
                        }
                    } else if str.hasPrefix("UIDevice") {
                        if let color = UIColorFromString(str) {
                            val = color
                        }
                    }
                }
            }
            self.type_handler.setter_handle(obj, "set" + method.uppercase_first() + ":", value: val, second: nil)
        }
        return nil
    }

    func typepair_chain(obj: AnyObject?, pair: TypePair) -> ChainResult {
        switch pair.first {
        case "string":
            return (.Stop, pair.second)
        case "int":
            return (.Go, pair.second)
        case "float":
            return (.Go, ValueObject(type: "f", value: pair.second))
        case "bool":
            return (.Go, ValueObject(type: "B", value: pair.second))
        case "address":
            return (.Go, from_address(String(pair.second)))
        case "symbol":
            if let str = pair.second as? String {
                switch str {
                case "nil":
                    return (.Stop, nil)
                default:
                    if let o = obj {
                        let sel = NSSelectorFromString(str)
                        if swift_property_names(o).contains(str) {
                            let (match, val) = type_handler.getter_handle(o, str)
                            if case .Match = match {
                                return (.Go, val)
                            } else {
                                return (.Go, swift_property_for_key(o, str))
                            }
                        } else if o.respondsToSelector(sel) {
                            let (match, val) = type_handler.getter_handle(o, str)
                            if case .Match = match {
                                return (.Go, val)
                            } else if nil == val {
                                return (.Stop, ValueObject(type: "nil", value: ""))
                            }
                        }
                    }
                }
            }
            return (.Stop, nil)

        case "call":
            if let nameargs = pair.second as? [AnyObject] {
                let (match, val) = typepair_callargs(obj, nameargs: nameargs)
                switch match {
                case .Match:
                    return (.Go, val)
                case .None:
                    return (.Stop, nil)
                }
            } else if let name = pair.second as? String {
                if let o = obj {
                    let (match, val) = type_handler.typepair_method(o, name: name, [])
                    switch match {
                    case .Match:
                        return (.Go, val)
                    case .None:
                        return (.Stop, nil)
                    }
                }
            }

        default:
            break
        }
        return (.Stop, nil)
    }

    func typepair_callargs(object: AnyObject?, nameargs: [AnyObject]) -> TypeMatchResult {
        if let name = nameargs.first as? String,
            let arguments = nameargs.last {
            if let obj = object {
                if let args = arguments as? [AnyObject] {
                    if 1 == args.count {
                        if let strargs = args[0] as? [String] {
                            if strargs == ["symbol", "nil"] {
                                return type_handler.typepair_method(obj, name: name, [ValueObject(type: "nil", value: "")])
                            }
                        }
                    }
                    return type_handler.typepair_method(obj, name: name, args)
                } else {
                    return type_handler.typepair_method(obj, name: name, [])
                }
            } else {
                switch arguments {
                case is [Float]:
                    return type_handler.typepair_function(name, arguments as! [Float])
                case is [AnyObject]:
                    if let args = arguments as? [[AnyObject]] {
                        return type_handler.typepair_constructor(name, args)
                    }
                default:
                    break
                }
            }
        }
        return (.None, nil)
    }

    func chain_dictionary(dict: [String: AnyObject], _ key: String, _ nth: Int, _ vec: [TypePair], full: Bool) -> ChainResult {
        if let obj = dict[key] {
            return chain(obj, vec.slice_to_end(nth), full: full)
        } else {
            switch key {
            case "keys":
                return chain([String](dict.keys), vec.slice_to_end(nth), full: full)
            case "values":
                return chain([AnyObject](dict.values), vec.slice_to_end(nth), full: full)
            default:
                break
            }
        }
        return (.Stop, dict)
    }

    func chain_array(arr: [AnyObject], _ method: String, _ nth: Int, _ vec: [TypePair], full: Bool) -> ChainResult {
        switch method {
        case "sort":
            if let a = arr as? [String] {
                return chain(a.sort(<), vec.slice_to_end(nth), full: full)
            }
        case "first":
            return chain(arr.first, vec.slice_to_end(nth), full: full)
        case "last":
            return chain(arr.last, vec.slice_to_end(nth), full: full)
        default:
            break
        }
        return (.Stop, arr)
    }

    func chain(object: AnyObject?, _ vec: [TypePair], full: Bool) -> ChainResult {
        if let obj = object {
            let cnt = vec.count
            for (idx,pair) in vec.enumerate() {
                if !full && idx == cnt-1 {
                    continue
                }
                let (match, val) = typepair_chain(obj, pair: pair)
                if case .Go = match {
                    if let method = self.var_or_method(pair) {
                        switch method {
                        case is Int:
                            if let arr = obj as? NSArray,
                                let idx = method as? Int {
                                if arr.count > idx {
                                    return chain(arr[idx], vec.slice_to_end(1), full: full)
                                }
                            }
                        default:
                            break
                        }
                    }
                    return chain(val, vec.slice_to_end(1), full: full)
                } else {
                    if let method = self.var_or_method(pair) {
                        switch method {
                        case is String:
                            let meth = method as! String
                            let (mat,ob) = type_handler.getter_handle(obj, meth)
                            if case .Match = mat {
                                if let o = ob {
                                    return chain(o, vec.slice_to_end(1), full: full)
                                } else {
                                    return (.Go, val)
                                }
                            } else if let dict = obj as? [String: AnyObject] {
                                return chain_dictionary(dict, meth, 1, vec, full: full)
                            } else if let arr = obj as? [AnyObject] {
                                return chain_array(arr, meth, 1, vec, full: full)
                            } else {
                                return (.Stop, val)
                            }
                        default:
                            break
                        }
                    }
                    return chain(val, vec.slice_to_end(1), full: full)
                }
            }
            return (.Go, obj)
        } else {
            if let pair = vec.first {
                let (cont, obj) = typepair_chain(nil, pair: pair)
                if case .Go = cont {
                    return chain(obj, vec.slice_to_end(1), full: full)
                } else {
                    if let one = pair.second as? String {
                        if let c: AnyClass = NSClassFromString(one) {
                            return chain(c, vec.slice_to_end(1), full: full)
                        } else if env.keys.contains(one) {
                            return chain(env[one], vec.slice_to_end(1), full: full)
                        } else {
                            let (mat,constant) = type_handler.typepair_constant(one)
                            if case .Match = mat {
                                return (.Go, constant)
                            } else {
                                return (.Stop, obj)
                            }
                        }
                    }
                }
            }
            return (.Stop, nil)
        }
    }
}

struct TypePair: CustomStringConvertible {
    var first: String
    var second: AnyObject
    var description: String {
        get {
            return "TypePair(\(first), \(second))"
        }
    }
}


// MARK: ConsoleRouter - utils

extension ConsoleRouter {

    public func register(name: String, object: AnyObject) {
        env[name] = object
    }

    func from_address(address: String) -> AnyObject? {
        var u: UInt64 = 0
        NSScanner(string: address).scanHexLongLong(&u)
        let ptr = UnsafeMutablePointer<UInt>(bitPattern: UInt(u))
        let obj = unsafeBitCast(ptr, AnyObject.self)
        return obj
    }

    func addressof(obj: AnyObject) -> String {
        return NSString(format: "%p", unsafeBitCast(obj, Int.self)) as String
    }

    func var_or_method(pair: TypePair) -> AnyObject? {
        switch pair.second {
        case is String:
            if let str = pair.second as? String {
                if str.hasSuffix("()") {
                    let method = str.slice(0, to: str.characters.count - 2)
                    return method
                } else if let num = Int(str) {
                    return num
                } else {
                    return str
                }
            }
        case is Int:
            if let num = pair.second as? Int {
                return num
            }
        default:
            break
        }
        return nil
    }

    func typepairs(syms: [AnyObject]) -> [TypePair] {
        var list = [TypePair]()
        for sym in syms {
            switch sym {
            case is Float:
                if String(sym).containsString(".") {
                    list.append(TypePair(first: "float", second: sym))
                } else {
                    list.append(TypePair(first: "int", second: sym))
                }
            case let n as Bool:
                list.append(TypePair(first: "bool", second: n))
            case let array as [AnyObject]:
                if array.count > 2 {
                    Log.info("array ", array)
                }
                list.append(TypePair(first: array[0] as! String, second: array[1]))
            case let str as String:
                list.append(TypePair(first: "string", second: str))
            case let any:
                Log.info("any", any)
                list.append(TypePair(first: "any", second: any))
            }
        }
        return list
    }
    
}



// MARK: ConsoleRouter - result
extension ConsoleRouter {
    func result(value: AnyObject) -> HttpResponse {
        switch value {
        case is ValueObject:
            if let val = value as? ValueObject {
                switch val.type {
                case "v":
                    return result_void()
                case "B":
                    return result_bool(val.value)
                case "{CGRect={CGPoint=dd}{CGSize=dd}}", "{CGRect={CGPoint=ff}{CGSize=ff}}":
                    return result_string(val.value)
                default:
                    if let num = val.value as? NSNumber {
                        if num.stringValue.containsString("e+") {
                            return result_any(String(num))
                        } else {
                            return result_any(num.floatValue)
                        }
                    } else {
                        return result_any(val.value)
                    }
                }
            }
        case is Int:
            return result_int(value)
        case is String:
            return result_string(value)
        case is UIView, is UIScreen:
            return .OK(.Json(["typ": "view", "address": addressof(value), "value": String(value)]))
        case is [String: AnyObject]:
            var d = [String: String]()
            for (k,v) in (value as! [String: AnyObject]) {
                d[k] = String(v)
            }
            return result_any(d)
        case is [AnyObject]:
            let a = (value as! [AnyObject]).map { x in String(x) }
            return result_any(a)
        default:
            break
        }
        return .OK(.Json(["typ": "any", "address": addressof(value), "value": String(value)]))
    }

    func result_any_with_address(value: AnyObject) -> HttpResponse {
        return .OK(.Json(["typ": "any", "address": addressof(value), "value": value]))
    }
    
    func result_any(value: AnyObject) -> HttpResponse {
        return .OK(.Json(["typ": "any", "value": value]))
    }

    func result_int(value: AnyObject) -> HttpResponse {
        return .OK(.Json(["typ": "any", "value": value]))
    }

    func result_string(value: AnyObject) -> HttpResponse {
        return .OK(.Json(["typ": "string", "value": value]))
    }

    func result_bool(value: AnyObject) -> HttpResponse {
        return .OK(.Json(["typ": "bool", "value": value]))
    }

    func result_void() -> HttpResponse {
        return .OK(.Json(["typ": "symbol", "value": "nothing"]))
    }

    func result_image(imagedata: NSData?) -> HttpResponse {
        let headers = ["Content-Type": "image/png"]
        if let data = imagedata {
            let writer: (HttpResponseBodyWriter -> Void) = { writer in
                writer.write(Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>(data.bytes), count: data.length)))
            }
            return .RAW(200, "OK", headers, writer)
        }
        return result_failed()
    }

    func result_nil() -> HttpResponse {
        return .OK(.Json(["typ": "symbol", "value": "nothing"]))
    }

    func result_failed(obj: AnyObject? = nil) -> HttpResponse {
        if let val = obj as? ValueObject {
            return .OK(.Json(["typ": val.type, "value": val.value]))
        } else {
            return .OK(.Json(["typ": "symbol", "value": "Failed"]))
        }
    }
}



// MARK: Swifter.HttpResponse - Equatable

public func ==(lhs: HttpResponse, rhs: HttpResponse) -> Bool {
    switch (lhs,rhs) {
    case let (.OK(.Json(lok)), .OK(.Json(rok))):
        return String(lok) == String(rok)
    default:
        break
    }
    return false
}