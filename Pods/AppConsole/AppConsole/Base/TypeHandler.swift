//
//  TypeHandler.swift
//  ConsoleApp
//
//  Created by wookyoung on 3/13/16.
//  Copyright © 2016 factorcat. All rights reserved.
//

import UIKit




class TypeHandler {

    // MARK: TypeHandler - getter_handle
    func getter_handle(obj: AnyObject, _ name: String, _ args: [AnyObject]? = nil) -> TypeMatchResult {
        if let val = obj as? ValueObject {
            return getter_valueobject(val, name)
        }
        
        let sel = Selector(name)
        if obj.respondsToSelector(sel) {
        } else if let nsobj = obj as? NSObject where ns_property_names(nsobj).contains(name) {
            return getter_property(nsobj, name)
        } else {
            if let _ = obj as? NSObject {
                let names = swift_property_names(obj)
                if names.contains(name) {
                    return (.Match, swift_property_for_key(obj, name))
                }
            } else {
                return (.None, nil)
            }
            return (.None, nil)
        }

        let returntype = ns_return_types(obj, name)
        switch returntype {
        case "v":
            obj.performSelector(sel)
            return (.Match, nil)
        case "@", "#":
            if let inst = obj.performSelector(sel) {
                if "Unmanaged<AnyObject>" == typeof(inst) {
                    return (.Match, convert(inst))
                } else {
                    return (.Match, inst as? AnyObject)
                }
            } else {
                return (.None, nil)
            }
        case "B": // B Bool
            typealias F = @convention(c) (AnyObject, Selector)-> Bool
            let value = extractMethodFrom(obj, sel, F.self)(obj, sel)
            return (.Match, ValueObject(type: returntype, value: value))
        case "d": // d Double
            typealias F = @convention(c) (AnyObject, Selector)-> Double
            let value = extractMethodFrom(obj, sel, F.self)(obj, sel)
            return (.Match, ValueObject(type: returntype, value: value))
        case "i", "q": // i int, q CLongLong
            typealias F = @convention(c) (AnyObject, Selector)-> Int
            let value = extractMethodFrom(obj, sel, F.self)(obj, sel)
            return (.Match, ValueObject(type: returntype, value: value))
        case "f": // f float
            typealias F = @convention(c) (AnyObject, Selector)-> Float
            let value = extractMethodFrom(obj, sel, F.self)(obj, sel)
            return (.Match, ValueObject(type: returntype, value: value))
        case "Q": // Q CUnsignedLongLong
            typealias F = @convention(c) (AnyObject, Selector)-> UInt
            let value = extractMethodFrom(obj, sel, F.self)(obj, sel)
            return (.Match, ValueObject(type: returntype, value: value))
        case "{CGPoint=dd}", "{CGPoint=ff}":
            typealias F = @convention(c) (AnyObject, Selector)-> CGPoint
            let value = extractMethodFrom(obj, sel, F.self)(obj, sel)
            return (.Match, ValueObject(type: returntype, value: NSStringFromCGPoint(value)))
        case "{CGSize=dd}", "{CGSize=ff}":
            typealias F = @convention(c) (AnyObject, Selector)-> CGSize
            let value = extractMethodFrom(obj, sel, F.self)(obj, sel)
            return (.Match, ValueObject(type: returntype, value: NSStringFromCGSize(value)))
        case "{CGRect={CGPoint=dd}{CGSize=dd}}", "{CGRect={CGPoint=ff}{CGSize=ff}}":
            typealias F = @convention(c) (AnyObject, Selector)-> CGRect
            let value = extractMethodFrom(obj, sel, F.self)(obj, sel)
            return (.Match, ValueObject(type: returntype, value: NSStringFromCGRect(value)))
        case "{CGAffineTransform=dddddd}":
            typealias F = @convention(c) (AnyObject, Selector)-> CGAffineTransform
            let value = extractMethodFrom(obj, sel, F.self)(obj, sel)
            return (.Match, ValueObject(type: returntype, value: NSStringFromCGAffineTransform(value)))
        case "{CATransform3D=dddddddddddddddd}":
            typealias F = @convention(c) (AnyObject, Selector)-> CATransform3D
            let value = extractMethodFrom(obj, sel, F.self)(obj, sel)
            return (.Match, ValueObject(type: returntype, value: NSStringFromCATransform3D(value)))
        case let val:
            Log.info("getter_handle val", val)
            break
        }
        return (.None, nil)
    }
    
    func getter_valueobject(val: ValueObject, _ name: String) -> TypeMatchResult {
        if let value = val.value as? String {
            switch val.type {
            case "{CGPoint=dd}", "{CGPoint=ff}":
                let point = CGPointFromString(value)
                switch name {
                case "x": return (.Match, point.x)
                case "y": return (.Match, point.y)
                default: return (.None, nil)
                }
            case "{CGSize=dd}", "{CGSize=ff}":
                let size = CGSizeFromString(value)
                switch name {
                case "width": return (.Match, size.width)
                case "height": return (.Match, size.height)
                default: return (.None, nil)
                }
            case "{CGRect={CGPoint=ff}{CGSize=ff}}":
                let rect = CGRectFromString(value)
                switch name {
                case "origin":
                    return (.Match, ValueObject(type: "{CGPoint=ff}", value: NSStringFromCGPoint(rect.origin)))
                case "size":
                    return (.Match, ValueObject(type: "{CGSize=ff}", value: NSStringFromCGSize(rect.size)))
                default:
                    return (.None, nil)
                }
            case "{CGRect={CGPoint=dd}{CGSize=dd}}":
                let rect = CGRectFromString(value)
                switch name {
                case "origin":
                    return (.Match, ValueObject(type: "{CGPoint=dd}", value: NSStringFromCGPoint(rect.origin)))
                case "size":
                    return (.Match, ValueObject(type: "{CGSize=dd}", value: NSStringFromCGSize(rect.size)))
                default:
                    return (.None, nil)
                }
            case "{CGAffineTransform=dddddd}":
                let transform = CGAffineTransformFromString(value)
                switch name {
                case "a": return (.Match, Float(transform.a))
                case "b": return (.Match, Float(transform.b))
                case "c": return (.Match, Float(transform.c))
                case "d": return (.Match, Float(transform.d))
                case "tx": return (.Match, Float(transform.tx))
                case "ty": return (.Match, Float(transform.ty))
                default:
                    return (.None, nil)
                }
            case "{CATransform3D=dddddddddddddddd}":
                let transform = CATransform3DFromString(value)
                switch name {
                case "m11": return (.Match, Float(transform.m11))
                case "m12": return (.Match, Float(transform.m12))
                case "m13": return (.Match, Float(transform.m13))
                case "m14": return (.Match, Float(transform.m14))
                case "m21": return (.Match, Float(transform.m21))
                case "m22": return (.Match, Float(transform.m22))
                case "m23": return (.Match, Float(transform.m23))
                case "m24": return (.Match, Float(transform.m24))
                case "m31": return (.Match, Float(transform.m31))
                case "m32": return (.Match, Float(transform.m32))
                case "m33": return (.Match, Float(transform.m33))
                case "m34": return (.Match, Float(transform.m34))
                case "m41": return (.Match, Float(transform.m41))
                case "m42": return (.Match, Float(transform.m42))
                case "m43": return (.Match, Float(transform.m43))
                case "m44": return (.Match, Float(transform.m44))
                default:
                    return (.None, nil)
                }
            default:
                return (.None, nil)
            }
        } else {
            return (.None, nil)
        }
    }

    // MARK: TypeHandler - getter_property
    func getter_property(obj: NSObject, _ name: String) -> TypeMatchResult {
        return (.Match, obj.valueForKey(name))
    }
    
    // MARK: TypeHandler - setter_handle
    func setter_handle(obj: AnyObject, _ method: String, value: AnyObject?, second: AnyObject?) {

        let sel = Selector(method)
        guard obj.respondsToSelector(sel) else {
            return
        }
        let argtype = (ns_argument_types(obj, method, nth: 2), ns_argument_types(obj, method, nth: 3))
        
        var arg: AnyObject? = nil
        if let val = value as? ValueObject {
            arg = val.value
        } else if let val = value {
            arg = val
        }

        switch argtype {
        case ("@",_):
            if nil == value {
                return
            }
            obj.performSelector(sel, withObject: arg)
        case ("B", _):
            if let a = arg as? Bool {
                typealias F = @convention(c) (AnyObject, Selector, Bool)-> Void
                self.extractMethodFrom(obj, sel, F.self)(obj, sel, a)
            } else {
                typealias F = @convention(c) (AnyObject, Selector, Bool)-> Void
                self.extractMethodFrom(obj, sel, F.self)(obj, sel, false)
            }
        case ("d", _):
            if let a = arg as? Double {
                typealias F = @convention(c) (AnyObject, Selector, Double) -> Void
                self.extractMethodFrom(obj, sel, F.self)(obj, sel, a)
            }
        case ("i","i"), ("q", "q"):
            if let a = arg as? Int, let b = second as? Int {
                typealias F = @convention(c) (AnyObject, Selector, Int, Int) -> Void
                self.extractMethodFrom(obj, sel, F.self)(obj, sel, a, b)
            }
        case ("i",_), ("q", _):
            if let a = arg as? Int {
                typealias F = @convention(c) (AnyObject, Selector, Int) -> Void
                self.extractMethodFrom(obj, sel, F.self)(obj, sel, a)
            }
        case ("f", _):
            if let a = arg as? Float {
                typealias F = @convention(c) (AnyObject, Selector, Float)-> Void
                self.extractMethodFrom(obj, sel, F.self)(obj, sel, a)
            }
        case ("Q", _):
            if let a = arg as? UInt {
                typealias F = @convention(c) (AnyObject, Selector, UInt)-> Void
                self.extractMethodFrom(obj, sel, F.self)(obj, sel, a)
            }
        case ("{CGPoint=dd}", _), ("{CGPoint=ff}", _):
            typealias F = @convention(c) (AnyObject, Selector, CGPoint) -> Void
            self.extractMethodFrom(obj, sel, F.self)(obj, sel, CGPointFromString(arg as! String))
        case ("{CGSize=dd}", _), ("{CGSize=ff}", _):
            typealias F = @convention(c) (AnyObject, Selector, CGSize) -> Void
            self.extractMethodFrom(obj, sel, F.self)(obj, sel, CGSizeFromString(arg as! String))
        case ("{CGRect={CGPoint=dd}{CGSize=dd}}",_), ("{CGRect={CGPoint=ff}{CGSize=ff}}",_):
            typealias F = @convention(c) (AnyObject, Selector, CGRect) -> Void
            self.extractMethodFrom(obj, sel, F.self)(obj, sel, CGRectFromString(arg as! String))
        case ("{CGAffineTransform=dddddd}", _):
            typealias F = @convention(c) (AnyObject, Selector, CGAffineTransform) -> Void
            self.extractMethodFrom(obj, sel, F.self)(obj, sel, CGAffineTransformFromString(arg as! String))
        case ("{CATransform3D=dddddddddddddddd}", _):
            typealias F = @convention(c) (AnyObject, Selector, CATransform3D) -> Void
            self.extractMethodFrom(obj, sel, F.self)(obj, sel, CATransform3DFromString(arg as! String))
        case let val:
            Log.info("setter_handle val", val)
        }
    }

    // MARK: TypeHandler - typepair_constant
    func typepair_constant(name: String) -> TypeMatchResult {
        switch name {
        case "CGPointZero":
            return (.Match, NSStringFromCGPoint(CGPointZero))
        case "CGSizeZero":
            return (.Match, NSStringFromCGSize(CGSizeZero))
        case "CGRectZero":
            return (.Match, NSStringFromCGRect(CGRectZero))
        case "CGAffineTransformIdentity":
            return (.Match, NSStringFromCGAffineTransform(CGAffineTransformIdentity))
        case "UIEdgeInsetsZero":
            return (.Match, NSStringFromUIEdgeInsets(UIEdgeInsetsZero))
        case "UIOffsetZero":
            return (.Match, NSStringFromUIOffset(UIOffsetZero))
        default:
            break
        }
        return (.None, nil)
    }

    func typeair_build_method(name: String, _ args: [AnyObject]) -> String {
        var method: String = name
        for (idx,arg) in args.enumerate() {
            if let named = arg as? [AnyObject] {
                if let para = named.first as? String {
                    if 0 == idx {
                        method += "With" + para.uppercase_first() + ":"
                    } else {
                        method += para + ":"
                    }
                }
            } else {
                method += ":"
            }
        }
        return method
    }

    func match_artype(argtype: String, _ arg: AnyObject?) -> Bool {
        switch argtype {
        case "@":
            if let _ = arg as? NSNumber {
                return false
            }
        default:
            break
        }
        return true
    }

    // MARK: TypeHandler - typepair_function
    func typepair_method(obj: AnyObject, name: String, _ args: [AnyObject]) -> TypeMatchResult {

        let method = typeair_build_method(name, args)
        let sel = NSSelectorFromString(method)
        
        guard obj.respondsToSelector(sel) else {
            return (.None, nil)
        }
        
        guard 0 < args.count else {
            return (.None, nil)
        }

        let returntype = ns_return_types(obj, method)
        let argtype = ns_argument_types(obj, method, nth: 2)

        var firstarg: AnyObject? = nil
        if let named = args[0] as? [AnyObject] {
            firstarg = named[1]
        } else if let value = args[0] as? ValueObject {
            firstarg = value.to_value()
        } else {
            firstarg = args[0]
        }

        if !match_artype(argtype, firstarg) {
            return (.None, nil)
        }

        switch args.count {
        case 1:
            switch returntype {
            case "v":
                return typepair_method_returns_void(obj, method, argtype, firstarg)
            case "@":
                return typepair_method_returns_instance(obj, method, argtype, firstarg)
            case "B":
                return typepair_method_returns_bool(obj, method, argtype, firstarg)
            case "q":
                return typepair_method_returns_int(obj, method, argtype, firstarg)
            case "f":
                return typepair_method_returns_float(obj, method, argtype, firstarg)
            case "{CGRect={CGPoint=dd}{CGSize=dd}}", "{CGRect={CGPoint=ff}{CGSize=ff}}":
                return typepair_method_returns_cgrect(obj, method, argtype, firstarg)
            default:
                Log.info("typepair_method", returntype, obj, method, argtype, firstarg)
                break
            }
            
        case 2:
            var secondarg: AnyObject? = nil
            if let named = args[1] as? [AnyObject] {
                secondarg = named[1]
            } else {
                secondarg = args[1]
            }
            switch returntype {
            case "v":
                return typepair_method_returns_void(obj, method, argtype, firstarg, second: secondarg)
            case "@":
                return typepair_method_returns_instance(obj, method, argtype, firstarg, second: secondarg)
            case "B":
                return typepair_method_returns_bool(obj, method, argtype, firstarg, second: secondarg)
            case "q":
                return typepair_method_returns_int(obj, method, argtype, firstarg, second: secondarg)
            case "f":
                return typepair_method_returns_float(obj, method, argtype, firstarg, second: secondarg)
            case "{CGRect={CGPoint=dd}{CGSize=dd}}", "{CGRect={CGPoint=ff}{CGSize=ff}}":
                return typepair_method_returns_cgrect(obj, method, argtype, firstarg, second: secondarg)
            default:
                Log.info("typepair_method", returntype, obj, method, argtype, firstarg, secondarg)
                break
            }
        default:
            Log.info("typepair_method", returntype, obj, method, argtype, firstarg)
            break
        }
        return (.None, nil)
    }

    func typepair_function(name: String, _ args: [Float]) -> TypeMatchResult {
        switch name {
        case "CGPointMake":
            if 2 == args.count {
                let point = CGPointMake(CGFloat(args[0]), CGFloat(args[1]))
                return (.Match, NSStringFromCGPoint(point))
            }
        case "CGSizeMake":
            if 2 == args.count {
                let size = CGSizeMake(CGFloat(args[0]), CGFloat(args[1]))
                return (.Match, NSStringFromCGSize(size))
            }
        case "CGVectorMake":
            if 2 == args.count {
                let vector = CGVectorMake(CGFloat(args[0]), CGFloat(args[1]))
                return (.Match, NSStringFromCGVector(vector))
            }
        case "CGRectMake":
            if 4 == args.count {
                let rect = CGRectMake(CGFloat(args[0]), CGFloat(args[1]), CGFloat(args[2]), CGFloat(args[3]))
                return (.Match, NSStringFromCGRect(rect))
            }
        case "CGAffineTransformMake":
            if 6 == args.count {
                let transform = CGAffineTransformMake(CGFloat(args[0]), CGFloat(args[1]), CGFloat(args[2]), CGFloat(args[3]), CGFloat(args[4]), CGFloat(args[5]))
                return (.Match, NSStringFromCGAffineTransform(transform))
            }
        case "UIEdgeInsetsMake":
            if 4 == args.count {
                let insets = UIEdgeInsetsMake(CGFloat(args[0]), CGFloat(args[1]), CGFloat(args[2]), CGFloat(args[3]))
                return (.Match, NSStringFromUIEdgeInsets(insets))
            }
        case "UIOffsetMake":
            if 2 == args.count {
                let offset = UIOffsetMake(CGFloat(args[0]), CGFloat(args[1]))
                return (.Match, NSStringFromUIOffset(offset))
            }

        default:
            Log.info("typepair_function", name, args)
            break
        }
        return (.None, nil)
    }

    // MARK: TypeHandler - typepair_constructor
    func typepair_constructor(name: String, _ args: [[AnyObject]]) -> TypeMatchResult {
        var dict = [String: AnyObject?]()
        for arg: [AnyObject] in args {
            if let k = arg.first as? String, let v = arg.last {
                dict[k] = v
            }
        }

        switch name {

        case "UIFont":
            if let name = dict["name"] as? String,
                let size = dict["size"] as? Float {
                return (.Match, UIFont(name: name, size: CGFloat(size)))
            }

        default:
            Log.info("typepair_constructor", name, dict)
            break
        }
        return (.None, nil)
    }

    func extractMethodFrom<U>(owner: AnyObject, _ selector: Selector, _ F: U.Type) -> U {
        let method: Method
        if owner is AnyClass {
            method = class_getClassMethod(owner as! AnyClass, selector)
        } else {
            method = class_getInstanceMethod(owner.dynamicType, selector)
        }
        let implementation: IMP = method_getImplementation(method)
        return unsafeBitCast(implementation, F.self)
    }

}



// MARK: ValueObject
class ValueObject: Equatable, CustomStringConvertible {
    var type: String
    var value: AnyObject
    init(type: String, value: AnyObject) {
        self.type = type
        self.value = value
    }
    var description: String {
        get {
            return "ValueObject(\(type), \(value))"
        }
    }
    func to_value() -> AnyObject? {
        if type == "nil" {
            return nil
        } else {
            return value
        }
    }
}

func ==(lhs: ValueObject, rhs: ValueObject) -> Bool {
    if lhs.type == rhs.type {
        switch lhs.type {
        case "d", "q", "Q":
            return lhs.value as? Double == rhs.value as? Double
        default:
            return lhs.value as? String == rhs.value as? String
        }
    } else {
        return false
    }
}


// MARK: UIFontFromString
func UIFontFromString(str: String) -> UIFont? {
    // <UICTFont: 0x7fe6cc035190> font-family: "Helvetica"; font-weight: normal; font-style: normal; font-size: 25.00pt
    if str.hasPrefix("<UICTFont: 0x") {
        let scan = NSScanner(string: str)
        scan.scanLocation = "<UICTFont: ".characters.count
        var a: Double = 0; scan.scanHexDouble(&a)
        scan.scanLocation += "> font-family: \"".characters.count
        var fontname: NSString? = nil
        scan.scanUpToString("\"", intoString: &fontname)
        var skip: NSString? = nil
        scan.scanUpToString("; font-size: ", intoString: &skip)
        scan.scanLocation += "; font-size: ".characters.count
        var fontsize: Float = 0; scan.scanFloat(&fontsize)
        if let name = fontname as? String {
            if let font = UIFont(name: name, size: CGFloat(fontsize)) {
                return font
            }
        }
    }
    return nil
}


// MARK: UIColorFromString
func UIColorFromString(str: String) -> UIColor? {
    if str.hasPrefix("UIDeviceRGBColorSpace") {
        let scan = NSScanner(string: str)
        scan.scanLocation = "UIDeviceRGBColorSpace ".characters.count
        var r: Float = 0; scan.scanFloat(&r)
        var g: Float = 0; scan.scanFloat(&g)
        var b: Float = 0; scan.scanFloat(&b)
        var a: Float = 0; scan.scanFloat(&a)
        return UIColor(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: CGFloat(a))
    } else if str.hasPrefix("UIDeviceWhiteColorSpace") {
        let scan = NSScanner(string: str)
        scan.scanLocation = "UIDeviceWhiteColorSpace ".characters.count
        var w: Float = 0; scan.scanFloat(&w)
        var a: Float = 0; scan.scanFloat(&a)
        return UIColor(white: CGFloat(w), alpha: CGFloat(a))
    } else {
        return nil
    }
}


// MARK: CATransform3D
func CATransform3DFromString(str: String) -> CATransform3D {
    let scan = NSScanner(string: str)
    scan.scanLocation = "CATransform3D(m11: ".characters.count
    var m11: Float = 0; scan.scanFloat(&m11); scan.scanLocation += 7
    var m12: Float = 0; scan.scanFloat(&m12); scan.scanLocation += 7
    var m13: Float = 0; scan.scanFloat(&m13); scan.scanLocation += 7
    var m14: Float = 0; scan.scanFloat(&m14); scan.scanLocation += 7
    var m21: Float = 0; scan.scanFloat(&m21); scan.scanLocation += 7
    var m22: Float = 0; scan.scanFloat(&m22); scan.scanLocation += 7
    var m23: Float = 0; scan.scanFloat(&m23); scan.scanLocation += 7
    var m24: Float = 0; scan.scanFloat(&m24); scan.scanLocation += 7
    var m31: Float = 0; scan.scanFloat(&m31); scan.scanLocation += 7
    var m32: Float = 0; scan.scanFloat(&m32); scan.scanLocation += 7
    var m33: Float = 0; scan.scanFloat(&m33); scan.scanLocation += 7
    var m34: Float = 0; scan.scanFloat(&m34); scan.scanLocation += 7
    var m41: Float = 0; scan.scanFloat(&m41); scan.scanLocation += 7
    var m42: Float = 0; scan.scanFloat(&m42); scan.scanLocation += 7
    var m43: Float = 0; scan.scanFloat(&m43); scan.scanLocation += 7
    var m44: Float = 0; scan.scanFloat(&m44)
    return CATransform3D(
        m11: CGFloat(m11), m12: CGFloat(m12), m13: CGFloat(m13), m14: CGFloat(m14),
        m21: CGFloat(m21), m22: CGFloat(m22), m23: CGFloat(m23), m24: CGFloat(m24),
        m31: CGFloat(m31), m32: CGFloat(m32), m33: CGFloat(m33), m34: CGFloat(m34),
        m41: CGFloat(m31), m42: CGFloat(m42), m43: CGFloat(m43), m44: CGFloat(m44))
}

func NSStringFromCATransform3D(transform: CATransform3D) -> String {
    return String(transform)
}


// methods
extension TypeHandler {
    func typepair_method_returns_void(obj: AnyObject, _ method: String, _ argtype: String, _ arg: AnyObject?, second: AnyObject? = nil) -> TypeMatchResult {
        self.setter_handle(obj, method, value: arg, second: second)
        return (.Match, ValueObject(type: "v", value: ""))
    }
    
    func typepair_method_returns_bool(obj: AnyObject, _ method: String, _ argtype: String, _ arg: AnyObject?, second: AnyObject? = nil) -> TypeMatchResult {
        let sel = Selector(method)
        var value: AnyObject? = nil
        switch argtype {
        case "B":
            if let a = arg as? Bool {
                typealias F = @convention(c) (AnyObject, Selector, Bool)-> Bool
                value = self.extractMethodFrom(obj, sel, F.self)(obj, sel, a)
            }
        case "d":
            if let a = arg as? Double {
                typealias F = @convention(c) (AnyObject, Selector, Double) -> Bool
                value = self.extractMethodFrom(obj, sel, F.self)(obj, sel, a)
            }
        case "i", "q":
            if let a = arg as? Int {
                typealias F = @convention(c) (AnyObject, Selector, Int) -> Bool
                value = self.extractMethodFrom(obj, sel, F.self)(obj, sel, a)
            }
        case "f":
            if let a = arg as? Float {
                typealias F = @convention(c) (AnyObject, Selector, Float)-> Bool
                value = self.extractMethodFrom(obj, sel, F.self)(obj, sel, a)
            }
        case "Q":
            if let a = arg as? UInt {
                typealias F = @convention(c) (AnyObject, Selector, UInt)-> Bool
                value = self.extractMethodFrom(obj, sel, F.self)(obj, sel, a)
            }
        case "@":
            if let a = arg as? String {
                typealias F = @convention(c) (AnyObject, Selector, String) -> Bool
                value = self.extractMethodFrom(obj, sel, F.self)(obj, sel, a)
            }
        case "{CGPoint=dd}", "{CGPoint=ff}":
            if let a = arg as? String {
                typealias F = @convention(c) (AnyObject, Selector, CGPoint) -> Bool
                value = self.extractMethodFrom(obj, sel, F.self)(obj, sel, CGPointFromString(a))
            }
        case "{CGSize=dd}", "{CGSize=ff}":
            if let a = arg as? String {
                typealias F = @convention(c) (AnyObject, Selector, CGSize) -> Bool
                value = self.extractMethodFrom(obj, sel, F.self)(obj, sel, CGSizeFromString(a))
            }
        case "{CGRect={CGPoint=dd}{CGSize=dd}}", "{CGRect={CGPoint=ff}{CGSize=ff}}":
            if let a = arg as? String {
                typealias F = @convention(c) (AnyObject, Selector, CGRect) -> Bool
                value = self.extractMethodFrom(obj, sel, F.self)(obj, sel, CGRectFromString(a))
            }
        case "{CGAffineTransform=dddddd}":
            if let a = arg as? String {
                typealias F = @convention(c) (AnyObject, Selector, CGAffineTransform) -> Bool
                value = self.extractMethodFrom(obj, sel, F.self)(obj, sel, CGAffineTransformFromString(a))
            }
        case "{CATransform3D=dddddddddddddddd}":
            if let a = arg as? String {
                typealias F = @convention(c) (AnyObject, Selector, CATransform3D) -> Bool
                value = self.extractMethodFrom(obj, sel, F.self)(obj, sel, CATransform3DFromString(a))
            }
        case let val:
            Log.info("typepair_method_returns_bool", val)
            break
        }
        if let v = value {
            let returntype = "B"
            return (.Match, ValueObject(type: returntype, value: v))
        } else {
            return  (.None, nil)
        }
    }

    func typepair_method_returns_int(obj: AnyObject, _ method: String, _ argtype: String, _ arg: AnyObject?, second: AnyObject? = nil) -> TypeMatchResult {
        let sel = Selector(method)
        var value: Int? = nil
        switch argtype {
        case "B":
            if let a = arg as? Bool {
                typealias F = @convention(c) (AnyObject, Selector, Bool)-> Int
                value = self.extractMethodFrom(obj, sel, F.self)(obj, sel, a)
            }
        case "d":
            if let a = arg as? Double {
                typealias F = @convention(c) (AnyObject, Selector, Double) -> Int
                value = self.extractMethodFrom(obj, sel, F.self)(obj, sel, a)
            }
        case "i", "q":
            if let a = arg as? Int {
                typealias F = @convention(c) (AnyObject, Selector, Int) -> Int
                value = self.extractMethodFrom(obj, sel, F.self)(obj, sel, a)
            }
        case "f":
            if let a = arg as? Float {
                typealias F = @convention(c) (AnyObject, Selector, Float)-> Int
                value = self.extractMethodFrom(obj, sel, F.self)(obj, sel, a)
            }
        case "Q":
            if let a = arg as? UInt {
                typealias F = @convention(c) (AnyObject, Selector, UInt)-> Int
                value = self.extractMethodFrom(obj, sel, F.self)(obj, sel, a)
            }
        case "@":
            if let a = arg as? String {
                typealias F = @convention(c) (AnyObject, Selector, String) -> Int
                value = self.extractMethodFrom(obj, sel, F.self)(obj, sel, a)
            }
        case "{CGPoint=dd}", "{CGPoint=ff}":
            if let a = arg as? String {
                typealias F = @convention(c) (AnyObject, Selector, CGPoint) -> Int
                value = self.extractMethodFrom(obj, sel, F.self)(obj, sel, CGPointFromString(a))
            }
        case "{CGSize=dd}", "{CGSize=ff}":
            if let a = arg as? String {
                typealias F = @convention(c) (AnyObject, Selector, CGSize) -> Int
                value = self.extractMethodFrom(obj, sel, F.self)(obj, sel, CGSizeFromString(a))
            }
        case "{CGRect={CGPoint=dd}{CGSize=dd}}", "{CGRect={CGPoint=ff}{CGSize=ff}}":
            if let a = arg as? String {
                typealias F = @convention(c) (AnyObject, Selector, CGRect) -> Int
                value = self.extractMethodFrom(obj, sel, F.self)(obj, sel, CGRectFromString(a))
            }
        case "{CGAffineTransform=dddddd}":
            if let a = arg as? String {
                typealias F = @convention(c) (AnyObject, Selector, CGAffineTransform) -> Int
                value = self.extractMethodFrom(obj, sel, F.self)(obj, sel, CGAffineTransformFromString(a))
            }
        case "{CATransform3D=dddddddddddddddd}":
            if let a = arg as? String {
                typealias F = @convention(c) (AnyObject, Selector, CATransform3D) -> Int
                value = self.extractMethodFrom(obj, sel, F.self)(obj, sel, CATransform3DFromString(a))
            }
        case let val:
            Log.info("typepair_method_returns_int", val)
            break
        }
        if let v = value {
            let returntype = "q"
            return (.Match, ValueObject(type: returntype, value: v))
        } else {
            return  (.None, nil)
        }
    }

    func typepair_method_returns_float(obj: AnyObject, _ method: String, _ argtype: String, _ arg: AnyObject?, second: AnyObject? = nil) -> TypeMatchResult {
        let sel = Selector(method)
        var value: AnyObject? = nil
        switch argtype {
        case "B":
            if let a = arg as? Bool {
                typealias F = @convention(c) (AnyObject, Selector, Bool)-> Float
                value = self.extractMethodFrom(obj, sel, F.self)(obj, sel, a)
            }
        case "d":
            if let a = arg as? Double {
                typealias F = @convention(c) (AnyObject, Selector, Double) -> Float
                value = self.extractMethodFrom(obj, sel, F.self)(obj, sel, a)
            }
        case "i", "q":
            if let a = arg as? Int {
                typealias F = @convention(c) (AnyObject, Selector, Int) -> Float
                value = self.extractMethodFrom(obj, sel, F.self)(obj, sel, a)
            }
        case "f":
            if let a = arg as? Float {
                typealias F = @convention(c) (AnyObject, Selector, Float)-> Float
                value = self.extractMethodFrom(obj, sel, F.self)(obj, sel, a)
            }
        case "Q":
            if let a = arg as? UInt {
                typealias F = @convention(c) (AnyObject, Selector, UInt)-> Float
                value = self.extractMethodFrom(obj, sel, F.self)(obj, sel, a)
            }
        case "@":
            if let a = arg as? String {
                typealias F = @convention(c) (AnyObject, Selector, String) -> Float
                value = self.extractMethodFrom(obj, sel, F.self)(obj, sel, a)
            }
        case "{CGPoint=dd}", "{CGPoint=ff}":
            if let a = arg as? String {
                typealias F = @convention(c) (AnyObject, Selector, CGPoint) -> Float
                value = self.extractMethodFrom(obj, sel, F.self)(obj, sel, CGPointFromString(a))
            }
        case "{CGSize=dd}", "{CGSize=ff}":
            if let a = arg as? String {
                typealias F = @convention(c) (AnyObject, Selector, CGSize) -> Float
                value = self.extractMethodFrom(obj, sel, F.self)(obj, sel, CGSizeFromString(a))
            }
        case "{CGRect={CGPoint=dd}{CGSize=dd}}", "{CGRect={CGPoint=ff}{CGSize=ff}}":
            if let a = arg as? String {
                typealias F = @convention(c) (AnyObject, Selector, CGRect) -> Float
                value = self.extractMethodFrom(obj, sel, F.self)(obj, sel, CGRectFromString(a))
            }
        case "{CGAffineTransform=dddddd}":
            if let a = arg as? String {
                typealias F = @convention(c) (AnyObject, Selector, CGAffineTransform) -> Float
                value = self.extractMethodFrom(obj, sel, F.self)(obj, sel, CGAffineTransformFromString(a))
            }
        case "{CATransform3D=dddddddddddddddd}":
            if let a = arg as? String {
                typealias F = @convention(c) (AnyObject, Selector, CATransform3D) -> Float
                value = self.extractMethodFrom(obj, sel, F.self)(obj, sel, CATransform3DFromString(a))
            }
        case let val:
            Log.info("typepair_method_returns_bool", val)
            break
        }
        if let v = value {
            let returntype = "f"
            return (.Match, ValueObject(type: returntype, value: v))
        } else {
            return (.None, nil)
        }
    }

    func typepair_method_returns_cgrect(obj: AnyObject, _ method: String, _ argtype: String, _ arg: AnyObject?, second: AnyObject? = nil) -> TypeMatchResult {
        let sel = Selector(method)
        var value: CGRect? = nil
        switch argtype {
        case "B":
            if let a = arg as? Bool {
                typealias F = @convention(c) (AnyObject, Selector, Bool)-> CGRect
                value = self.extractMethodFrom(obj, sel, F.self)(obj, sel, a)
            }
        case "d":
            if let a = arg as? Double {
                typealias F = @convention(c) (AnyObject, Selector, Double) -> CGRect
                value = self.extractMethodFrom(obj, sel, F.self)(obj, sel, a)
            }
        case "i", "q":
            if let a = arg as? Int {
                typealias F = @convention(c) (AnyObject, Selector, Int) -> CGRect
                value = self.extractMethodFrom(obj, sel, F.self)(obj, sel, a)
            }
        case "f":
            if let a = arg as? Float {
                typealias F = @convention(c) (AnyObject, Selector, Float)-> CGRect
                value = self.extractMethodFrom(obj, sel, F.self)(obj, sel, a)
            }
        case "Q":
            if let a = arg as? UInt {
                typealias F = @convention(c) (AnyObject, Selector, UInt)-> CGRect
                value = self.extractMethodFrom(obj, sel, F.self)(obj, sel, a)
            }
        case "@":
            if let a = arg as? String {
                typealias F = @convention(c) (AnyObject, Selector, String) -> CGRect
                value = self.extractMethodFrom(obj, sel, F.self)(obj, sel, a)
            }
        case "{CGPoint=dd}", "{CGPoint=ff}":
            if let a = arg as? String {
                typealias F = @convention(c) (AnyObject, Selector, CGPoint) -> CGRect
                value = self.extractMethodFrom(obj, sel, F.self)(obj, sel, CGPointFromString(a))
            }
        case "{CGSize=dd}", "{CGSize=ff}":
            if let a = arg as? String {
                typealias F = @convention(c) (AnyObject, Selector, CGSize) -> CGRect
                value = self.extractMethodFrom(obj, sel, F.self)(obj, sel, CGSizeFromString(a))
            }
        case "{CGRect={CGPoint=dd}{CGSize=dd}}", "{CGRect={CGPoint=ff}{CGSize=ff}}":
            if let a = arg as? String {
                typealias F = @convention(c) (AnyObject, Selector, CGRect) -> CGRect
                value = self.extractMethodFrom(obj, sel, F.self)(obj, sel, CGRectFromString(a))
            }
        case "{CGAffineTransform=dddddd}":
            if let a = arg as? String {
                typealias F = @convention(c) (AnyObject, Selector, CGAffineTransform) -> CGRect
                value = self.extractMethodFrom(obj, sel, F.self)(obj, sel, CGAffineTransformFromString(a))
            }
        case "{CATransform3D=dddddddddddddddd}":
            if let a = arg as? String {
                typealias F = @convention(c) (AnyObject, Selector, CATransform3D) -> CGRect
                value = self.extractMethodFrom(obj, sel, F.self)(obj, sel, CATransform3DFromString(a))
            }
        case let val:
            Log.info("typepair_method_returns_cgrect", val)
            break
        }
        if let v = value {
            let returntype = "{CGRect={CGPoint=ff}{CGSize=ff}}"
            return (.Match, ValueObject(type: returntype, value: NSStringFromCGRect(v)))
        } else {
            return (.None, nil)
        }
    }

    func typepair_method_returns_instance(obj: AnyObject, _ method: String, _ argtype: String, _ arg: AnyObject?, second: AnyObject? = nil) -> TypeMatchResult {
        let sel = Selector(method)
        var value: AnyObject? = nil

        switch argtype {
        case "B":
            if let a = arg as? Bool {
                typealias F = @convention(c) (AnyObject, Selector, Bool)-> AnyObject
                value = self.extractMethodFrom(obj, sel, F.self)(obj, sel, a)
            }
        case "d":
            if let a = arg as? Double {
                typealias F = @convention(c) (AnyObject, Selector, Double) -> AnyObject
                value = self.extractMethodFrom(obj, sel, F.self)(obj, sel, a)
            }
        case "i", "q":
            if let a = arg as? Int {
                typealias F = @convention(c) (AnyObject, Selector, Int) -> AnyObject
                value = self.extractMethodFrom(obj, sel, F.self)(obj, sel, a)
            }
        case "f":
            if let a = arg as? Float {
                typealias F = @convention(c) (AnyObject, Selector, Float)-> AnyObject
                value = self.extractMethodFrom(obj, sel, F.self)(obj, sel, a)
            }
        case "Q":
            if let a = arg as? UInt {
                typealias F = @convention(c) (AnyObject, Selector, UInt)-> AnyObject
                value = self.extractMethodFrom(obj, sel, F.self)(obj, sel, a)
            }
        case "@":
            if let a = arg as? String {
                typealias F = @convention(c) (AnyObject, Selector, String) -> AnyObject
                typealias F2 = @convention(c) (AnyObject, Selector, String, String) -> AnyObject
                if let b = second as? String {
                    value = self.extractMethodFrom(obj, sel, F2.self)(obj, sel, a, b)
                } else {
                    value = self.extractMethodFrom(obj, sel, F.self)(obj, sel, a)
                }
            } else {
                typealias F = @convention(c) (AnyObject, Selector, AnyObject?) -> AnyObject
                value = self.extractMethodFrom(obj, sel, F.self)(obj, sel, arg)
            }
        case "{CGPoint=dd}", "{CGPoint=ff}":
            if let a = arg as? String {
                typealias F = @convention(c) (AnyObject, Selector, CGPoint) -> AnyObject
                value = self.extractMethodFrom(obj, sel, F.self)(obj, sel, CGPointFromString(a))
            }
        case "{CGSize=dd}", "{CGSize=ff}":
            if let a = arg as? String {
                typealias F = @convention(c) (AnyObject, Selector, CGSize) -> AnyObject
                value = self.extractMethodFrom(obj, sel, F.self)(obj, sel, CGSizeFromString(a))
            }
        case "{CGRect={CGPoint=dd}{CGSize=dd}}", "{CGRect={CGPoint=ff}{CGSize=ff}}":
            if let a = arg as? String {
                typealias F = @convention(c) (AnyObject, Selector, CGRect) -> AnyObject
                value = self.extractMethodFrom(obj, sel, F.self)(obj, sel, CGRectFromString(a))
            }
        case "{CGAffineTransform=dddddd}":
            if let a = arg as? String {
                typealias F = @convention(c) (AnyObject, Selector, CGAffineTransform) -> AnyObject
                value = self.extractMethodFrom(obj, sel, F.self)(obj, sel, CGAffineTransformFromString(a))
            }
        case "{CATransform3D=dddddddddddddddd}":
            if let a = arg as? String {
                typealias F = @convention(c) (AnyObject, Selector, CATransform3D) -> AnyObject
                value = self.extractMethodFrom(obj, sel, F.self)(obj, sel, CATransform3DFromString(a))
            }
        case let val:
            Log.info("typepair_method_returns_bool", val)
            break
        }
        return (.Match, value)
    }
}


