//
//  Extensions.swift
//  ConsoleApp
//
//  Created by wookyoung on 3/13/16.
//  Copyright © 2016 factorcat. All rights reserved.
//

import UIKit
import CoreData


// MARK: NSManagedObjectContext - fetch
extension NSManagedObjectContext {
    func fetch(entityName: String) -> [AnyObject] {
        return fetch(entityName, predicate: "")
    }
    func fetch(entityName: String, predicate: String) -> [AnyObject] {
        let fetchReq = NSFetchRequest(entityName: entityName)
        if !predicate.isEmpty {
            fetchReq.predicate = NSPredicate(format: predicate)
        }
        do {
            return try executeFetchRequest(fetchReq)
        } catch {
            return []
        }
    }
}


// MARK: UITableView - tap
extension UITableView {
    func tap(section section: Int, row: Int) {
        if let cell = cellForRowAtIndexPath(NSIndexPath(forRow: row, inSection: section)) {
            cell.tap()
        }
    }
    
    func tap(index index: Int) {
        if index > numberOfRowsInSection(0) {
        } else {
            self.tap(section: 0, row: index)
        }
    }
    
    func tap(text text: String) {
        for section in 0..<numberOfSections {
            for row in 0..<numberOfRowsInSection(section) {
                if let cell = cellForRowAtIndexPath(NSIndexPath(forRow: row, inSection: section)) {
                    if cell.textLabel?.text == text {
                        cell.tap()
                        return
                    }
                }
            }
        }
    }
}

// MARK: UITableViewCell - tap
extension UITableViewCell {
    func tap() {
        if let tableView = self.superview?.superview as? UITableView,
            let indexPath = tableView.indexPathForCell(self) {
            dispatch_async(dispatch_get_main_queue(), {
                tableView.delegate?.tableView?(tableView, willSelectRowAtIndexPath: indexPath)
                self.selected = true
                let delay = 0.2 * Double(NSEC_PER_SEC)
                let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
                dispatch_after(time, dispatch_get_main_queue(), {
                    tableView.delegate?.tableView?(tableView, didSelectRowAtIndexPath: indexPath)
                    self.selected = false
                })
            })
        }
    }
}


// MARK: UINavigationItem - tap
//extension UINavigationItem {
//    func tap() {
//        
//    }
//}

// MARK: UISegmentedControl - tap
extension UISegmentedControl {
    func tap(index index: Int) {
        if index < numberOfSegments {
            dispatch_async(dispatch_get_main_queue(), {
                self.selectedSegmentIndex = index
            })
            for controlEvent in Array(arrayLiteral: allControlEvents()) {
                switch controlEvent {
                case UIControlEvents.ValueChanged:
                    self.sendActionsForControlEvents(controlEvent)
                default:
                    break
                }
            }
        }
    }
    
    func tap(title title: String) {
        for index in 0..<numberOfSegments {
            if let str = titleForSegmentAtIndex(index) {
                if str == title {
                    dispatch_async(dispatch_get_main_queue(), {
                        self.selectedSegmentIndex = index
                    })
                    for controlEvent in Array(arrayLiteral: allControlEvents()) {
                        switch controlEvent {
                        case UIControlEvents.ValueChanged:
                            self.sendActionsForControlEvents(controlEvent)
                        default:
                            break
                        }
                    }
                }
            }
        }
    }
}

// MARK: UISlider - tap
extension UISlider {
    func tap(value value: Float) {
        dispatch_async(dispatch_get_main_queue(), {
            self.value = value
        })
        for controlEvent in Array(arrayLiteral: allControlEvents()) {
            switch controlEvent {
            case UIControlEvents.ValueChanged:
                self.sendActionsForControlEvents(controlEvent)
            default:
                break
            }
        }
    }
}

// MARK: UISwitch - tap
extension UISwitch {
    func tap() {
        let onOff = !on
        dispatch_async(dispatch_get_main_queue(), {
            self.setOn(onOff, animated: true)
        })
        for controlEvent in Array(arrayLiteral: allControlEvents()) {
            switch controlEvent {
            case UIControlEvents.ValueChanged:
                self.sendActionsForControlEvents(controlEvent)
            default:
                break
            }
        }
    }
}

// MARK: UIButton - tap
extension UIButton {
    func tap() {
        for controlEvent in Array(arrayLiteral: allControlEvents()) {
            switch controlEvent {
            case UIControlEvents.TouchUpInside:
                dispatch_async(dispatch_get_main_queue(), {
                    let shadowColor = self.titleShadowColorForState(.Selected)
                    self.setTitleShadowColor(.blueColor(), forState: .Selected)
                    self.selected = true
                    let delay = 0.2 * Double(NSEC_PER_SEC)
                    let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
                    dispatch_after(time, dispatch_get_main_queue(), {
                        self.setTitleShadowColor(shadowColor, forState: .Selected)
                        self.sendActionsForControlEvents(controlEvent)
                        self.selected = false
                    })
                })
            default:
                Log.info("controlEvent", controlEvent)
                break
            }
        }
    }
}



// MARK: UINavigationController - pop

extension UINavigationController {
    func pop() {
        dispatch_async(dispatch_get_main_queue(), {
            self.popViewControllerAnimated(true)
        })
    }
}



// MARK: UIView - to_data

extension UIView {
    func to_data() -> NSData? {
        if bounds.size == CGSizeZero {
            return nil
        } else {
            if typeof(self).hasPrefix("_") {
                return nil
            } else {
                UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, UIScreen.mainScreen().scale)
                self.drawViewHierarchyInRect(self.bounds, afterScreenUpdates: false)
                let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                return UIImagePNGRepresentation(image)
            }
        }
    }
}



// MARK: UIScreen - to_data

extension UIScreen {
    func to_data() -> NSData? {
        let app = UIApplication.sharedApplication()
        if let window = app.keyWindow {
            UIGraphicsBeginImageContextWithOptions(window.frame.size, window.opaque, 0.0)
            window.layer.renderInContext(UIGraphicsGetCurrentContext()!)
            if !app.statusBarHidden {
                // is private api?
                if let statusBar = app.valueForKey("statusBarWindow") {
                    statusBar.layer.renderInContext(UIGraphicsGetCurrentContext()!)
                }
            }
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return UIImagePNGRepresentation(image)
        } else {
            return nil
        }

//        // disabled touch events after this
//        let view = self.snapshotViewAfterScreenUpdates(false)
//        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, self.scale)
//        view.drawViewHierarchyInRect(view.bounds, afterScreenUpdates: true)
//        let image = UIGraphicsGetImageFromCurrentImageContext()
//        UIGraphicsEndImageContext()
//        return UIImagePNGRepresentation(image)
    }
}



// MARK: String

extension String {
    func uppercase_first() -> String {
        switch self.characters.count {
        case 0:
            return ""
        case 1:
            return uppercaseString
        default:
            return String(self[characters.startIndex.advancedBy(0)]).uppercaseString + self.slice_to_end(1)
        }
    }
    
    public func slice_to_end(index: Int) -> String {
        return self.substringFromIndex(self.startIndex.advancedBy(index))
    }
    
    func slice(from: Int, to: Int) -> String {
        return self[self.startIndex.advancedBy(from)..<self.startIndex.advancedBy(to)]
    }
}


// MARK: Array

extension Array {
    func slice_to_end(nth: Int) -> Array {
        if nth < self.endIndex {
            let s: ArraySlice = self[nth..<self.endIndex]
            return Array(s)
        } else {
            return Array()
        }
    }
}


// MARK: typeof
func typeof(a: Any) -> String {
    let mirror = Mirror(reflecting: a)
    return String(mirror.subjectType)
}

// MARK: convert
func convert(a: Any) -> AnyObject? {
    if let obj = a as? Unmanaged<AnyObject> {
        return obj.takeUnretainedValue()
    } else {
        return nil
    }
}

// MARK: ns_return_types
func ns_return_types(obj: AnyObject, _ name: String) -> String {
    let m: Method = class_getInstanceMethod(object_getClass(obj), Selector(name))
    let returnType = method_copyReturnType(m)
    defer {
        returnType.destroy()
    }
    if let str = String.fromCString(returnType) {
        return str
    } else {
        return ""
    }
}

// MARK: ns_argument_types
func ns_argument_types(obj: AnyObject, _ name: String, nth: Int) -> String {
    let m: Method = class_getInstanceMethod(object_getClass(obj), Selector(name))
    let argumentType = method_copyArgumentType(m, UInt32(nth))
    defer {
        argumentType.destroy()
    }
    if let str = String.fromCString(argumentType) {
        return str
    } else {
        return ""
    }
}

// MARK: ns_property_names
func ns_property_names(obj: NSObject) -> Array<String> {
    let myClass: AnyClass = object_getClass(obj)
    var results: Array<String> = []
    var count: UInt32 = 0
    let properties = class_copyPropertyList(myClass, &count)
    for i: UInt32 in 0 ..< count {
        let property = properties[Int(i)]
        let cname = property_getName(property)
        if let name = String.fromCString(cname) {
            results.append(name)
        }
    }
    free(properties)
    return results
}

func swift_property_names(a: AnyObject) -> [String] {
    return Mirror(reflecting: a).children.filter { $0.label != nil }.map { $0.label! }
}

func swift_property_for_key(a: AnyObject, _ key: String) -> AnyObject? {
    for child in Mirror(reflecting: a).children {
        if child.label == key {
            if String(typeof(child.value)).hasPrefix("(") {
                return ValueObject(type: typeof(child.value), value: String(child.value))
            } else {
                return child.value as? AnyObject
            }
        }
    }
    return nil
}

// MARK: ns_protocol_names
func ns_protocol_names(obj: NSObject) -> Array<String> {
    let myClass: AnyClass = object_getClass(obj)
    var results: Array<String> = []
    var count: UInt32 = 0
    let protocols: AutoreleasingUnsafeMutablePointer<Protocol?> = class_copyProtocolList(myClass, &count)
    for i: UInt32 in 0 ..< count {
        let protoco = protocols[Int(i)]
        let cname = protocol_getName(protoco)
        if let name = String.fromCString(cname) {
            results.append(name)
        }
    }
//    free(protocols)
    return results
}

// MARK: ns_ivar_names
func ns_ivar_names(obj: NSObject) -> Array<String> {
    let myClass: AnyClass = object_getClass(obj)
    var results: Array<String> = []
    var count: UInt32 = 0
    let ivars: UnsafeMutablePointer<Ivar> = class_copyIvarList(myClass, &count)
    for i: UInt32 in 0 ..< count {
        let ivar = ivars[Int(i)]
        let cname = ivar_getName(ivar)
        if let name = String.fromCString(cname) {
            results.append(name)
        }
    }
    free(ivars)
    return results
}


// MARK: UnitTest

// using some part of bnickel/RestorationDefender.swift
// https://gist.github.com/bnickel/410a1bdc02f12fbd9b5e

func enumerateCArray<T>(array: UnsafePointer<T>, count: UInt32, f: (UInt32, T) -> ()) {
    var ptr = array
    for i in 0..<count {
        f(i, ptr.memory)
        ptr = ptr.successor()
    }
}

func methodName(m: Method) -> String? {
    let sel = method_getName(m)
    let nameCString = sel_getName(sel)
    return String.fromCString(nameCString)
}

public func objc_TestClassList() -> [AnyClass] {
    let expectedClassCount = objc_getClassList(nil, 0)
    let allClasses = UnsafeMutablePointer<AnyClass?>.alloc(Int(expectedClassCount))
    let autoreleasingAllClasses = AutoreleasingUnsafeMutablePointer<AnyClass?>(allClasses)
    let actualClassCount:Int32 = objc_getClassList(autoreleasingAllClasses, expectedClassCount)
    
    var classes = [AnyClass]()
    for i in 0 ..< actualClassCount {
        if let currentClass: AnyClass = allClasses[Int(i)] {
            if String(currentClass).hasSuffix("Tests") {
                classes.append(currentClass)
            }
        }
    }
    allClasses.dealloc(Int(expectedClassCount))
    return classes
}

public func testMethodsForClass(cls: AnyClass) -> [String] {
    var methodCount: UInt32 = 0
    let methodList = class_copyMethodList(cls, &methodCount)
    var list = [String]()
    if methodList != nil && methodCount > 0 {
        enumerateCArray(methodList, count: methodCount) { i, m in
            if let name = methodName(m) {
                if name.hasPrefix("test") {
                    list.append(name)
                }
            }
        }
        free(methodList)
    }
    return list
}

struct TestResult {
    var tests: Int
    var passed: Int
    var failed: Int
    var errors: Int
}

let ansi_escape = "\u{001b}["
let ansi_brown  = ansi_escape + "fg52,91,151;"
let ansi_red    = ansi_escape + "fg215,50,50;"
let ansi_green  = ansi_escape + "fg0,155,0;"
let ansi_reset  = ansi_escape + ";"

class UnitTest {
    static var tests: Int = 0
    static var passed: Int = 0
    static var failed: Int = 0
    static var errors: Int = 0
    
    class func runClasses(classes: [AnyClass]) {
        for c in classes {
            switch c {
            case let classInst as NSObject.Type:
                let instance = classInst.init()
                for name in testMethodsForClass(c) {
                    instance.performSelector(NSSelectorFromString(name))
                    tests += 1
                }
            default:
                break
            }
        }
    }
    
    class func run(only only: String) -> TestResult {
        return run(only: [only])
    }
    
    class func run(only only: [String] = [String]()) -> TestResult {
        let started_at = NSDate()
        print("Started")
        if only.count > 0 {
            var list = [AnyClass]()
            for name in only {
                let bundleName = NSBundle.mainBundle().objectForInfoDictionaryKey(kCFBundleNameKey as String) as! String
                if let c: AnyClass = NSClassFromString("\(bundleName).\(name)") {
                    list.append(c)
                }
            }
            runClasses(list)
        } else {
            runClasses(objc_TestClassList())
        }
        
        let elapsed: NSTimeInterval = -started_at.timeIntervalSinceNow
        print(String(format: "\nFinished in %.3g seconds.", elapsed))
        if failed > 0 {
            print(ansi_red)
        } else if passed > 0 {
            print(ansi_green)
        }
        print(String(format: "%d tests, %d assertions, %d failures, %d errors",
            tests, passed, failed, errors))
        print(ansi_reset)
        return TestResult(tests: tests, passed: passed, failed: failed, errors: errors)
    }
}




// MARK: Logger

class Logger {
    func info(args: Any..., file: StaticString = #file, function: String = #function, line: UInt = #line) {
        let filename = (String(file) as NSString).lastPathComponent
        
        var str = ""
        str += "\(filename) #\(line) "
        str += "\(function) "
        let length = args.count
        for (index, x) in args.enumerate() {
            str += String(x)
            if length==index+1 {
                
            } else {
                str += " "
            }
        }
        str += "\n"
        print(str)
    }
}

let Log = Logger()