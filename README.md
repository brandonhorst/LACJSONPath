LACJSONPath
===========

A simple Objective-C Implementation of JSONPath, as described in http://goessner.net/articles/JsonPath/

This is implemented as a category on NSDictionary and NSArray. It can therefore be used with any NSDictionary or NSArray that only contains other NSDictionaries, NSArrays, NSNumbers, and so forth. It was designed for use on objects created with [NSJSONSerialization](https://developer.apple.com/library/mac/documentation/Foundation/Reference/NSJSONSerialization_Class/Reference/Reference.html), but it should work for any such collections. It does not (primarily) make use of KVC, and as such cannot be used with custom NSObjects with Properties.

Some simple Unit Tests are included. There are many cases that have not yet been tested: this should not by any means be considered ready for production.

The main difference between this and the original Javascript implementation is the use of eval statements: [(...)] and [?(...)].

[(...)] statements are simply not permitted. Because Objective-C lacks the ability to execute arbitrary code, there is no sane way to implement this. Most functionality should be able to be achieved using slice notation.

[?(...)] filter statements are allowed, and make use of the NSPredicate functionality. Unlike the Javascript implementation, it will only search current-level nodes, it will not walk the object tree. If you would like to filter recursively, you can use ..[?("filter")] syntax.

This is a simple port of the original [Javascript implementation](http://code.google.com/p/jsonpath/), and is not optimized. I suspect that a substantial speedup could be achieved if the Javascript-like code was replaced with more Objective-C-like code.