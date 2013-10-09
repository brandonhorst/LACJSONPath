//
//  LACJSONPathTests.m
//  LACJSONPathTests
//
//  Created by Brandon Horst on 10/3/13.
//  Copyright (c) 2013 Brandon Horst. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "NSObjects+LACJSONPath.h"

@interface LACJSONPathTests : XCTestCase

@end

@implementation LACJSONPathTests {
    NSDictionary* obj;
}

- (void)setUp
{
    [super setUp];
    NSString* json = @"{\"store\":{\"book\":[{\"category\":\"reference\",\"author\":\"NigelRees\",\"title\":\"SayingsoftheCentury\",\"price\":8.95},{\"category\":\"fiction\",\"author\":\"EvelynWaugh\",\"title\":\"SwordofHonour\",\"price\":8.99},{\"category\":\"fiction\",\"author\":\"HermanMelville\",\"title\":\"MobyDick\",\"isbn\":\"0-553-21311-3\",\"price\":12.99},{\"category\":\"fiction\",\"author\":\"J.R.R.Tolkien\",\"title\":\"TheLordoftheRings\",\"isbn\":\"0-395-19395-8\",\"price\":22.99}],\"bicycle\":{\"color\":\"red\",\"price\":19.95}}}";
    obj = [NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
}

- (void)tearDown
{
    
    [super tearDown];
}

- (void) testJSONPath {
    NSArray* allAuthors = @[@"NigelRees",@"EvelynWaugh",@"HermanMelville",@"J.R.R.Tolkien"];
    NSArray* allPrices = @[@8.95,@8.99,@12.99,@22.99,@19.95];
    NSArray* firstTwoBooks = [obj[@"store"][@"book"] subarrayWithRange:NSMakeRange(0, 2)];
    NSArray* lastTwoBooks = [obj[@"store"][@"book"] subarrayWithRange:NSMakeRange(2, 2)];
    
    XCTAssertEqualObjects([obj parseWithJSONPath:@"$.store.book[*].author"],
                          allAuthors,
                          @"All Authors");
    
    XCTAssertEqualObjects([obj parseWithJSONPath:@"$..author"], allAuthors, @"All Authors recursive");
    
    XCTAssertEqualObjects([obj parseWithJSONPath:@"$.store.*"], [[obj objectForKey:@"store"] allValues], @"Store Star");
    
    XCTAssertEqualObjects([obj parseWithJSONPath:@"$.store..price"], allPrices, @"All Prices Recursive");
    
    XCTAssertEqualObjects([obj parseWithJSONPath:@"$..book[2]"], @[obj[@"store"][@"book"][2]], @"third book");
    
    XCTAssertEqualObjects([obj parseWithJSONPath:@"$..book[-1:]"], @[obj[@"store"][@"book"][3]], @"last book");
    
    XCTAssertEqualObjects([obj parseWithJSONPath:@"$..book[0,1]"], firstTwoBooks, @"two book comma");
    
    XCTAssertEqualObjects([obj parseWithJSONPath:@"$..book[:2]"], firstTwoBooks, @"two book slice");
    
    XCTAssertEqualObjects([obj parseWithJSONPath:@"$..book[?(@.isbn != nil)]"],
                          lastTwoBooks,
                          @"exists filter");
                          
    XCTAssertEqualObjects([obj parseWithJSONPath:@"$..book[?(@.price < 10)]"],
                          firstTwoBooks,
                          @"comparison filter");
    
//    XCTAssertEqualObjects([obj parseWithJSONPath:@"$..*"],
//                          ;
}

@end
