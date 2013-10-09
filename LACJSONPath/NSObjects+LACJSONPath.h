//
//  NSString+LACJSONPath.h
//  Lacona
//
//  Created by Brandon Horst on 10/3/13.
//  Copyright (c) 2013 Brandon Horst. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (LACJSONPath)

-(NSString*) parseWithJSONPath:(NSString*)jsonPath;

@end

@interface NSArray (LACJSONPath)

-(NSString*) parseWithJSONPath:(NSString*)jsonPath;

@end
