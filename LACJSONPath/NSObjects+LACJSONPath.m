//
//  NSString+LACJSONPath.m
//  Lacona
//
//  Created by Brandon Horst on 10/3/13.
//  Copyright (c) 2013 Brandon Horst. All rights reserved.
//

#import "NSObjects+LACJSONPath.h"





@interface SharedCode : NSObject

@end



@implementation SharedCode

+(NSString*) normalizeJSONPath:(NSString*)jsonPath {
    NSMutableString* workingString = [NSMutableString stringWithString:jsonPath];
    NSMutableArray* subx = [[NSMutableArray alloc] init];
    NSRegularExpression* regex1 = [NSRegularExpression regularExpressionWithPattern:@"[\\['](\\??\\(.*?\\))[\\]']" options:0 error:nil];
    NSRegularExpression* regex2 = [NSRegularExpression regularExpressionWithPattern:@"'?\\.'?|\\['?" options:0 error:nil];
    NSRegularExpression* regex3 = [NSRegularExpression regularExpressionWithPattern:@";;;|;;" options:0 error:nil];
    NSRegularExpression* regex4 = [NSRegularExpression regularExpressionWithPattern:@";$|'?\\]|'$" options:0 error:nil];
    NSRegularExpression* regex5 = [NSRegularExpression regularExpressionWithPattern:@"#([0-9]+)" options:0 error:nil];
    
    
    [regex1 enumerateMatchesInString:[workingString copy] options:0 range:NSMakeRange(0, workingString.length) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop) {
        NSString* identifier = [NSString stringWithFormat:@"[#%li]", subx.count];
        [subx addObject:[workingString substringWithRange:[match rangeAtIndex:1]]];
        [workingString replaceCharactersInRange:match.range withString:identifier];
    }];
    [regex2 replaceMatchesInString:workingString options:0 range:NSMakeRange(0, workingString.length) withTemplate:@";"];
    [regex3 replaceMatchesInString:workingString options:0 range:NSMakeRange(0, workingString.length) withTemplate:@";..;"];
    [regex4 replaceMatchesInString:workingString options:0 range:NSMakeRange(0, workingString.length) withTemplate:@""];
    [regex5 enumerateMatchesInString:[workingString copy] options:0 range:NSMakeRange(0, workingString.length) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop) {
        NSUInteger identifierPos = [[workingString substringWithRange:[match rangeAtIndex:1]] integerValue];
        [workingString replaceCharactersInRange:match.range withString:[subx objectAtIndex:identifierPos]];
    }];
    return [NSString stringWithString:workingString];
}


+(void) traceWithExpression:(NSString*)expression value:(id)value path:(NSString*)path results:(NSMutableArray*)results {
    if (expression.length) {
        NSRange separatorRange = [expression rangeOfString:@";"];
        NSString* location;
        NSString* newExpression;
        if (separatorRange.location != NSNotFound) {
            location = [expression substringToIndex:separatorRange.location];
            newExpression = [expression substringFromIndex:separatorRange.location+1];
        } else {
            location = expression;
            newExpression = @"";
        }
        id result = nil;
        if ([value isKindOfClass:[NSArray class]] && [location stringByTrimmingCharactersInSet:[NSCharacterSet decimalDigitCharacterSet]].length == 0) {
            result = [value objectAtIndex:[location integerValue]];
        } else if ([value isKindOfClass:[NSDictionary class]]) {
            result = [value objectForKey:location];
        }

        if (result != nil) {
            [SharedCode traceWithExpression:newExpression value:result path:[NSString stringWithFormat:@"%@;%@",path,location] results:results];
        } else if ([location isEqualToString:@"*"]) {
            [SharedCode walkLocation:location expression:expression value:value path:path callback: ^(NSString* key, id object, NSString* location,NSString* expression,NSString* path) {
                [SharedCode traceWithExpression:[NSString stringWithFormat:@"%@;%@",key,newExpression] value:value path:path results:results];
            }];
        } else if ([location isEqualToString:@".."]) {
            [SharedCode traceWithExpression:newExpression value:value path:path results:results];
            [SharedCode walkLocation:location expression:newExpression value:value path:path callback:^(NSString* key, id object, NSString* location,NSString* expression,NSString* path) {
                if (object != nil && ([object isKindOfClass:[NSDictionary class]] || [object isKindOfClass:[NSArray class]])) {
                    [SharedCode traceWithExpression:[NSString stringWithFormat:@"..;%@",newExpression] value:object path:[NSString stringWithFormat:@"%@;%@",path,key] results:results];
                }
            }];
        } else if ([location rangeOfString:@","].location != NSNotFound) {
            for (NSString* component in [location componentsSeparatedByString:@","]) {
                [SharedCode traceWithExpression:[NSString stringWithFormat:@"%@;%@",component,newExpression] value:value path:path results:results];
            }
//        } else if ([location hasPrefix:@"("] && [location hasSuffix:@")"]) {
//            [SharedCode traceWithExpression:[NSString stringWithFormat:@"%@;%@", [SharedCode evalPredicate:[location substringWithRange:NSMakeRange(1, location.length-2)] onObject:value],newExpression] value:value path:path results:results];
        } else if ([location hasPrefix:@"?("] && [location hasSuffix:@")"]) {
//            [SharedCode walkLocation:location expression:newExpression value:value path:path callback:^(NSString* key, id object, NSString* location,NSString* expression,NSString* path) {
            if ([value isKindOfClass:[NSArray class]]) {
                NSPredicate* predicate = [NSPredicate predicateWithFormat:[[location substringWithRange:NSMakeRange(2, location.length-3)] stringByReplacingOccurrencesOfString:@"@" withString:@"SELF"]];
                NSUInteger i = 0;
                for (id object in value) {
                    if ([predicate evaluateWithObject:object]) {
                        [SharedCode traceWithExpression:[NSString stringWithFormat:@"%li;%@",i,newExpression] value:value path:path results:results];
                    }
                    ++i;
                }
            }
        } else if ([[NSRegularExpression regularExpressionWithPattern:@"^(-?[0-9]*):(-?[0-9]*):?([0-9]*)$" options:0 error:nil] numberOfMatchesInString:location options:0 range:NSMakeRange(0, location.length)] > 0) {
            [SharedCode sliceWithLocation:location expression:newExpression value:value path:path results:results];
        }
    } else {
        [results addObject:value];
    }
}
+(void) walkLocation:(NSString*)location expression:(NSString*)expression value:(id)value path:(NSString*)path callback:(void (^)(NSString*,id,NSString*,NSString*,NSString*))callback {
    if ([value isKindOfClass:[NSArray class]]) {
        NSUInteger i = 0;
        for (id obj in value) {
            callback([NSString stringWithFormat:@"%li",i],obj,location,expression,path);
            ++i;
        }
    } else if ([value isKindOfClass:[NSDictionary class]]) {
        for (NSString* key in value) {
            callback(key, [value objectForKey:key],location,expression,path);
        }
    }
}



+(void) sliceWithLocation:(NSString*)location expression:(NSString*)expression value:(id)value path:(NSString*)path results:(NSMutableArray*)results {
    __block NSUInteger length = [value count];
    __block NSInteger start = 0;
    __block NSInteger end = length;
    __block NSInteger step = 1;
    
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@"^(-?[0-9]*):(-?[0-9]*):?(-?[0-9]*)$" options:0 error:nil];
    [regex enumerateMatchesInString:location options:0 range:NSMakeRange(0, location.length) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop) {
        NSRange startRange = [match rangeAtIndex:1];
        NSRange endRange = [match rangeAtIndex:2];
        NSRange stepRange = [match rangeAtIndex:3];
        if (startRange.length != 0) {
            start = [[location substringWithRange:startRange] integerValue];
        }
        if (endRange.length != 0) {
            end = [[location substringWithRange:endRange] integerValue];
        }
        if (stepRange.length != 0) {
            step = [[location substringWithRange:stepRange] integerValue];
        }
    }];
    
    start = start < 0 ? MAX(0,start+length) : MIN(length,start);
    end =   end < 0   ? MAX(0,end+length)   : MIN(length,end);
    
    for (NSUInteger i=start; i<end; i+=step) {
        [SharedCode traceWithExpression:[NSString stringWithFormat:@"%li;%@",i,expression] value:value path:path results:results];
    }
}

//+(id) evalPredicate:(NSString*)predicateString onObject:(id)object {
//    NSPredicate* predicate = [NSPredicate predicateWithFormat:predicateString];
//    object
//}


+(id) parseObject:(id)object withJSONPath:(NSString*)jsonPath {
    NSMutableArray* results = [[NSMutableArray alloc] init];
    NSString* normalizedExpr = [SharedCode normalizeJSONPath:jsonPath];
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@"^\\$;" options:0 error:nil];
    normalizedExpr = [regex stringByReplacingMatchesInString:normalizedExpr options:0 range:NSMakeRange(0, normalizedExpr.length) withTemplate:@""];
    [SharedCode traceWithExpression:normalizedExpr value:object path:@"$" results:results];
    
    return results;
}

@end




@implementation NSDictionary (LACJSONPath)

-(id) parseWithJSONPath:(NSString*)jsonPath {
    return [SharedCode parseObject:self withJSONPath:jsonPath];
}

@end


@implementation NSArray (LACJSONPath)

-(id) parseWithJSONPath:(NSString*)jsonPath {
    return [SharedCode parseObject:self withJSONPath:jsonPath];
}

@end

