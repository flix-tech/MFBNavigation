//
//  MFBUIKitUnwindTokenFactory.h
//  MFBNavigation
//
//  Created by Nikolay Kasyanov on 19.07.17.
//  Copyright © 2017 FlixBus GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MFBUIKitUnwindToken.h"

NS_ASSUME_NONNULL_BEGIN

@interface MFBUIKitUnwindTokenFactory : NSObject

- (MFBUIKitUnwindToken *)unwindTokenWithDelegate:(id<MFBUIKitUnwindDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
