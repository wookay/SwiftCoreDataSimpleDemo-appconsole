Run Demo App
============

Download Demo Sample (forked from iascchen/SwiftCoreDataSimpleDemo)
https://github.com/wookay/SwiftCoreDataSimpleDemo-appconsole/archive/master.zip

```
$ cd SwiftCoreDataSimpleDemo-appconsole-master

SwiftCoreDataSimpleDemo-appconsole-master $ pod update

SwiftCoreDataSimpleDemo-appconsole-master $ open SwiftCoreDataSimpleDemo.xcworkspace
```

* Run the project



Commands with Swifter.jl
========================

You need to install Julia programming language.
* Get download julia-0.4.6-osx10.7+.dmg and Install
http://julialang.org/downloads/


* Run Julia
```
julia> Pkg.add("Swifter")



julia> using Swifter

julia> a = initial("http://localhost:8080")
<SwiftCoreDataSimpleDemo.AppDelegate: 0x7f93e2e05d80>


press > key


Swifter> a.cdh.managedObjectContext.fetch("Member", predicate: "name == 'Butter'")
0 Member(name: Butter, birthday: nil, sex: , family: Fruits)

Swifter> a.cdh.managedObjectContext.fetch("Member", predicate: "name CONTAINS 'B'")
0 Member(name: Butter, birthday: nil, sex: , family: Fruits)
1 Member(name: Bread, birthday: nil, sex: , family: Fruits)

Swifter> a.cdh.managedObjectContext.fetch("Member")
0 Member(name: Butter, birthday: nil, sex: , family: Fruits)
1 Member(name: Coffee, birthday: nil, sex: , family: Fruits)
2 Member(name: Cheese, birthday: nil, sex: , family: Fruits)
3 Member(name: Cereal, birthday: nil, sex: , family: Fruits)
4 Member(name: Sausages, birthday: nil, sex: , family: Fruits)
5 Member(name: Milk, birthday: nil, sex: , family: Fruits)
6 Member(name: Bread, birthday: nil, sex: , family: Fruits)
7 Member(name: Orange Juice, birthday: nil, sex: , family: Fruits)
8 Member(name: Tomatoes, birthday: nil, sex: , family: Fruits)
9 Member(name: Eggs, birthday: nil, sex: , family: Fruits)
10 Member(name: Apples, birthday: nil, sex: , family: Fruits)
11 Member(name: Fish, birthday: nil, sex: , family: Fruits)

Swifter> a.cdh.managedObjectContext.fetch("Family", predicate: "name CONTAINS 'B'")
0 Family(name: Bread, address: , members: 0)
1 Family(name: Butter, address: , members: 0)
```



Differences from iascchen/SwiftCoreDataSimpleDemo
==================================================

Here's required code to apply for your own project.

* Podfile
```
use_frameworks!

target 'SwiftCoreDataSimpleDemo' do
  pod 'AppConsole'
end
```


* AppDelegate.swift
```
import AppConsole

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    ...
        AppConsole(initial: self).run()
    }
```


* Core Data model description
```
// Family.swift
class Family: NSManagedObject {
    ...
    override var description: String {
        return "Family(name: \(name), address: \(address), members: \(members.count))"
    }


// Member.swift
class Member: NSManagedObject {
    ...
    override var description: String {
        return "Member(name: \(name), birthday: \(birthday), sex: \(sex), family: \(family.name))"
    }
```


References
==========

* https://github.com/wookay/AppConsole
* https://github.com/wookay/Swifter.jl
