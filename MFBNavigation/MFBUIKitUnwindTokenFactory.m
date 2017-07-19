//
//  MFBUIKitUnwindTokenFactory.m
//  MFBNavigation
//
//  Created by Nikolay Kasyanov on 19.07.17.
//  Copyright © 2017 FlixBus GmbH. All rights reserved.
//

#import "MFBUIKitUnwindTokenFactory.h"

@implementation MFBUIKitUnwindTokenFactory

- (MFBUIKitUnwindToken *)unwindTokenWithDelegate:(id<MFBUIKitUnwindDelegate>)delegate
{
    NSCParameterAssert(delegate != nil);

    __auto_type token = [MFBUIKitUnwindToken new];
    token.delegate = delegate;
    return token;
}

@end
